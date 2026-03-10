#!/bin/bash -e
# ============================================================
# Compare Two Performance Test Result Sets (A/B Comparison)
# ============================================================
# Usage:
#   ./compare-results.sh results/default_20260221_120000 results/updated_20260221_130000
#
# Parses JTL files from two test runs and generates a side-by-side
# comparison report showing per-step metrics and overall deltas.
#
# Output: Printed to stdout (pipe to file if needed)
#   ./compare-results.sh results/A results/B > comparison.md

if [ $# -ne 2 ]; then
    echo "Usage: $0 <results-dir-A> <results-dir-B>"
    echo ""
    echo "Example:"
    echo "  $0 results/default_20260221_120000 results/updated_20260221_130000"
    exit 1
fi

DIR_A="$1"
DIR_B="$2"

# Find the scenario JTL file (skip setup_*.jtl and report-gen.log)
find_scenario_jtl() {
    local dir="$1"
    local jtl
    jtl=$(find "$dir" -maxdepth 1 -name "*.jtl" ! -name "setup_*" | head -1)
    if [ -z "$jtl" ]; then
        echo "ERROR: No scenario JTL file found in $dir" >&2
        exit 1
    fi
    echo "$jtl"
}

JTL_A=$(find_scenario_jtl "$DIR_A")
JTL_B=$(find_scenario_jtl "$DIR_B")

LABEL_A=$(basename "$DIR_A")
LABEL_B=$(basename "$DIR_B")

echo "# Performance Comparison Report"
echo ""
echo "| | Run A | Run B |"
echo "|---|---|---|"
echo "| **Label** | $LABEL_A | $LABEL_B |"
echo "| **JTL** | $(basename "$JTL_A") | $(basename "$JTL_B") |"
echo ""

# Parse JTL CSV and compute per-label metrics using Python
# JTL CSV format: timeStamp,elapsed,label,responseCode,responseMessage,threadName,
#                 dataType,success,failureMessage,bytes,sentBytes,grpThreads,allThreads,
#                 URL,Latency,IdleTime,Connect
parse_jtl() {
    local jtl_file="$1"
    # Output: label | count | avg_ms | p95_ms | error_count | error_pct
    python3 - "$jtl_file" <<'PYEOF'
import csv, sys, math
from collections import defaultdict

jtl_file = sys.argv[1]
data = defaultdict(lambda: {"elapsed": [], "errors": 0})

with open(jtl_file, newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
        label = row["label"]
        data[label]["elapsed"].append(int(row["elapsed"]))
        if row["success"].strip().lower() == "false":
            data[label]["errors"] += 1

for label in sorted(data.keys()):
    d = data[label]
    vals = sorted(d["elapsed"])
    count = len(vals)
    avg = sum(vals) / count if count > 0 else 0
    p95_idx = max(0, int(math.ceil(count * 0.95)) - 1)
    p95 = vals[p95_idx] if count > 0 else 0
    err = d["errors"]
    err_pct = (err / count) * 100 if count > 0 else 0
    print(f"{label}|{count}|{avg:.0f}|{p95:.0f}|{err}|{err_pct:.1f}")
PYEOF
}

# Parse both JTL files
METRICS_A=$(parse_jtl "$JTL_A")
METRICS_B=$(parse_jtl "$JTL_B")

# Build the comparison table
echo "## Per-Step Comparison"
echo ""
echo "| Step | Samples A | Samples B | Avg (ms) A | Avg (ms) B | Delta | P95 (ms) A | P95 (ms) B | Delta | Err% A | Err% B |"
echo "|------|-----------|-----------|------------|------------|-------|------------|------------|-------|--------|--------|"

# Join metrics by label
paste <(echo "$METRICS_A" | sort -t'|' -k1,1) <(echo "$METRICS_B" | sort -t'|' -k1,1) | while IFS=$'\t' read -r line_a line_b; do
    if [ -z "$line_a" ] || [ -z "$line_b" ]; then
        continue
    fi

    IFS='|' read -r label_a cnt_a avg_a p95_a err_a errp_a <<< "$line_a"
    IFS='|' read -r label_b cnt_b avg_b p95_b err_b errp_b <<< "$line_b"

    if [ "$label_a" != "$label_b" ]; then
        continue
    fi

    # Calculate deltas
    avg_delta=$(awk "BEGIN { d = $avg_b - $avg_a; printf \"%+.0f\", d }")
    p95_delta=$(awk "BEGIN { d = $p95_b - $p95_a; printf \"%+.0f\", d }")

    # Format delta with percentage
    if [ "$avg_a" != "0" ]; then
        avg_pct=$(awk "BEGIN { printf \"%+.1f%%\", (($avg_b - $avg_a) / $avg_a) * 100 }")
    else
        avg_pct="N/A"
    fi
    if [ "$p95_a" != "0" ]; then
        p95_pct=$(awk "BEGIN { printf \"%+.1f%%\", (($p95_b - $p95_a) / $p95_a) * 100 }")
    else
        p95_pct="N/A"
    fi

    printf "| %s | %s | %s | %s | %s | %s (%s) | %s | %s | %s (%s) | %s%% | %s%% |\n" \
        "$label_a" "$cnt_a" "$cnt_b" "$avg_a" "$avg_b" "$avg_delta" "$avg_pct" \
        "$p95_a" "$p95_b" "$p95_delta" "$p95_pct" "$errp_a" "$errp_b"
done

echo ""

# Overall summary
echo "## Overall Summary"
echo ""

compute_overall() {
    local metrics="$1"
    echo "$metrics" | awk -F'|' '
    {
        total_count += $2
        total_elapsed += ($3 * $2)  # avg * count = total elapsed
        total_errors += $5
    }
    END {
        avg = (total_count > 0) ? total_elapsed / total_count : 0
        err_pct = (total_count > 0) ? (total_errors / total_count) * 100 : 0
        tps = total_count  # Will be divided by duration externally
        printf "%d|%.0f|%d|%.2f", total_count, avg, total_errors, err_pct
    }
    '
}

OVERALL_A=$(compute_overall "$METRICS_A")
OVERALL_B=$(compute_overall "$METRICS_B")

IFS='|' read -r cnt_a avg_a err_a errp_a <<< "$OVERALL_A"
IFS='|' read -r cnt_b avg_b err_b errp_b <<< "$OVERALL_B"

avg_delta=$(awk "BEGIN { printf \"%+.0f\", $avg_b - $avg_a }")
if [ "$avg_a" != "0" ]; then
    avg_pct=$(awk "BEGIN { printf \"%+.1f%%\", (($avg_b - $avg_a) / $avg_a) * 100 }")
else
    avg_pct="N/A"
fi

echo "| Metric | Run A | Run B | Delta |"
echo "|--------|-------|-------|-------|"
echo "| Total Samples | $cnt_a | $cnt_b | — |"
echo "| Avg Response Time (ms) | $avg_a | $avg_b | $avg_delta ($avg_pct) |"
echo "| Total Errors | $err_a | $err_b | — |"
echo "| Error Rate | ${errp_a}% | ${errp_b}% | — |"
echo ""
echo "---"
echo "*Negative delta = Run B is faster (improvement). Positive delta = Run B is slower (regression).*"
