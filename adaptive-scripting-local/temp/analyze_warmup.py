#!/usr/bin/env python3
"""Analyze warm-up contamination in JTL results."""
import csv
import sys
import os

jtl_file = sys.argv[1] if len(sys.argv) > 1 else "results/default_50emp_5min_20260312_210944/Adaptive_Script_RoleBased_Flow.jtl"

with open(jtl_file) as f:
    reader = csv.DictReader(f)
    rows = list(reader)

ts = [int(r['timeStamp']) for r in rows]
start = min(ts)
end = max(ts)
duration_s = (end - start) / 1000
print(f"Test duration: {duration_s:.0f}s ({duration_s/60:.1f}min)")
print(f"Total samples: {len(rows)}")
print()

# Thread ramp-up in first 35s
print("=== Thread count during first 35s (ramp-up) ===")
for sec in range(0, 40, 5):
    ws = start + sec * 1000
    we = start + (sec + 5) * 1000
    window = [r for r in rows if ws <= int(r['timeStamp']) < we]
    if window:
        threads = [int(r['allThreads']) for r in window]
        elapsed = [int(r['elapsed']) for r in window]
        avg_lat = sum(elapsed) / len(elapsed)
        max_lat = max(elapsed)
        print(f"  T={sec:3d}-{sec+5:3d}s: samples={len(window):5d}, threads={min(threads):2d}-{max(threads):2d}, avg_latency={avg_lat:.0f}ms, max_latency={max_lat}ms")

# Percentiles helper
def percentiles(values, label):
    vals = sorted(values)
    n = len(vals)
    if n == 0:
        print(f"  (no data)")
        return
    print(f"  Samples: {n}")
    print(f"  P50: {vals[int(n*0.50)]}ms")
    print(f"  P90: {vals[int(n*0.90)]}ms")
    print(f"  P95: {vals[int(n*0.95)]}ms")
    print(f"  P99: {vals[int(n*0.99)]}ms")
    print(f"  Max: {vals[-1]}ms")
    print(f"  Avg: {sum(vals)/n:.0f}ms")

all_elapsed = [int(r['elapsed']) for r in rows]
print()
print("=== Overall percentiles (ALL samples, no warm-up removal) ===")
percentiles(all_elapsed, "all")

# Strip first 30s
warmed = [int(r['elapsed']) for r in rows if int(r['timeStamp']) > start + 30000]
print()
print("=== Percentiles AFTER removing first 30s ===")
percentiles(warmed, "warmed")

# Strip first 60s
warmed60 = [int(r['elapsed']) for r in rows if int(r['timeStamp']) > start + 60000]
print()
print("=== Percentiles AFTER removing first 60s ===")
percentiles(warmed60, "warmed60")

# Per-step breakdown - first 30s vs rest
print()
print("=== Per-step: Ramp-up (first 30s) vs Steady-state ===")
labels = sorted(set(r['label'] for r in rows))
for label in labels:
    rampup_vals = [int(r['elapsed']) for r in rows if r['label'] == label and int(r['timeStamp']) <= start + 30000]
    steady_vals = [int(r['elapsed']) for r in rows if r['label'] == label and int(r['timeStamp']) > start + 30000]
    if rampup_vals and steady_vals:
        r_avg = sum(rampup_vals) / len(rampup_vals)
        s_avg = sum(steady_vals) / len(steady_vals)
        r_max = max(rampup_vals)
        s_max = max(steady_vals)
        print(f"  {label}")
        print(f"    Ramp-up:  n={len(rampup_vals):5d}, avg={r_avg:6.0f}ms, max={r_max}ms")
        print(f"    Steady:   n={len(steady_vals):5d}, avg={s_avg:6.0f}ms, max={s_max}ms")
        print(f"    Avg diff: {r_avg - s_avg:+.0f}ms ({((r_avg - s_avg)/s_avg*100) if s_avg else 0:+.1f}%)")
