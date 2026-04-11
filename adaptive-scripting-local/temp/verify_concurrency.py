#!/usr/bin/env python3
"""Verify actual concurrent thread counts from JTL data."""
import csv
import sys
import os

base = os.path.dirname(os.path.abspath(__file__))
results_dir = os.path.join(base, "..", "results")

# Find JTL files to analyze
jtl_files = []
for d in sorted(os.listdir(results_dir)):
    full = os.path.join(results_dir, d)
    if not os.path.isdir(full):
        continue
    for f in os.listdir(full):
        if f.endswith(".jtl") and not f.startswith("setup_"):
            jtl_files.append((d, os.path.join(full, f)))

# Analyze select tests
targets = [
    "default_50emp_5min_20260312_210944",
    "default_200emp_10min_20260302_081604",
    "default_1000emp_5min_20260225_152901",
]

for target in targets:
    matches = [(name, path) for name, path in jtl_files if name == target]
    if not matches:
        print(f"SKIP: {target} not found")
        continue

    name, path = matches[0]
    print(f"\n{'='*70}")
    print(f"Test: {name}")
    print(f"{'='*70}")

    with open(path) as f:
        reader = csv.DictReader(f)
        rows = list(reader)

    ts = [int(r["timeStamp"]) for r in rows]
    start_ts = min(ts)
    end_ts = max(ts)
    duration_s = (end_ts - start_ts) / 1000

    # Steady state = after 60s, before last 10s
    steady = [r for r in rows if start_ts + 60000 < int(r["timeStamp"]) < end_ts - 10000]
    if not steady:
        steady = [r for r in rows if int(r["timeStamp"]) > start_ts + 30000]

    threads = [int(r["allThreads"]) for r in steady]
    grp_threads = [int(r["grpThreads"]) for r in steady]

    # Count unique thread names
    all_thread_names = set(r["threadName"] for r in rows)
    steady_thread_names = set(r["threadName"] for r in steady)

    print(f"  Duration: {duration_s:.0f}s ({duration_s/60:.1f}min)")
    print(f"  Total samples: {len(rows)}")
    print(f"  Steady-state samples (60s-end): {len(steady)}")
    print(f"  ")
    print(f"  allThreads at steady state:")
    print(f"    min={min(threads)}, max={max(threads)}")
    from collections import Counter
    tc = Counter(threads)
    top3 = tc.most_common(3)
    print(f"    Most common: {top3}")
    print(f"  grpThreads at steady state:")
    print(f"    min={min(grp_threads)}, max={max(grp_threads)}")
    gc = Counter(grp_threads)
    top3g = gc.most_common(3)
    print(f"    Most common: {top3g}")
    print(f"  ")
    print(f"  Unique thread names (total): {len(all_thread_names)}")
    print(f"  Unique thread names (steady): {len(steady_thread_names)}")

    # Show a few thread names
    sorted_names = sorted(all_thread_names)
    for t in sorted_names[:3]:
        print(f"    {t}")
    if len(sorted_names) > 6:
        print(f"    ...")
        for t in sorted_names[-3:]:
            print(f"    {t}")

    # Check: does thread count match expected concurrency?
    # Try to extract from log file
    log_path = path.replace(".jtl", ".log")
    conc_from_log = None
    if os.path.exists(log_path):
        with open(log_path) as lf:
            for line in lf:
                if "concurrency=" in line or "-Jconcurrency=" in line:
                    import re
                    m = re.search(r'concurrency=(\d+)', line)
                    if m:
                        conc_from_log = int(m.group(1))
                        break
    if conc_from_log:
        print(f"  ")
        print(f"  Configured concurrency (from log): {conc_from_log}")
        mode_thread = max(set(threads), key=threads.count)
        if mode_thread == conc_from_log:
            print(f"  MATCH: allThreads mode ({mode_thread}) == configured concurrency ({conc_from_log})")
        else:
            print(f"  MISMATCH: allThreads mode ({mode_thread}) != configured concurrency ({conc_from_log})")
