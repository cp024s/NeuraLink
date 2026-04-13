#!/usr/bin/env python3
import argparse
import csv
import json
import pathlib
from statistics import mean

from logging_utils import get_logger


TARGET_METRICS = [
  ("latency_cycles", "lower"),
  ("throughput_ops_per_cycle", "higher"),
  ("efficiency", "higher"),
]
LOG = get_logger("baseline_compare")


def load_rows(path: pathlib.Path):
  rows = []
  with path.open(newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
      rows.append(row)
  return rows


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--metrics-csv", required=True)
  parser.add_argument("--baseline-json", required=True)
  parser.add_argument("--out-json", required=True)
  args = parser.parse_args()

  rows = load_rows(pathlib.Path(args.metrics_csv))
  baseline = json.loads(pathlib.Path(args.baseline_json).read_text())
  base_vals = baseline["baseline_metrics"]

  aggregates = {}
  for k, _ in TARGET_METRICS:
    vals = [float(r[k]) for r in rows] if rows else [0.0]
    aggregates[k] = mean(vals)

  comparisons = []
  for k, direction in TARGET_METRICS:
    ours = aggregates[k]
    base = float(base_vals[k])
    if direction == "lower":
      delta_pct = ((base - ours) / base) * 100 if base != 0 else 0.0
      better = ours < base
    else:
      delta_pct = ((ours - base) / base) * 100 if base != 0 else 0.0
      better = ours > base
    comparisons.append({
      "metric": k,
      "direction": direction,
      "ours": round(ours, 6),
      "baseline": round(base, 6),
      "delta_pct": round(delta_pct, 3),
      "better": better
    })

  out = {
    "baseline_name": baseline.get("name", "baseline_model"),
    "baseline_note": baseline.get("note", ""),
    "comparisons": comparisons
  }
  pathlib.Path(args.out_json).write_text(json.dumps(out, indent=2))
  LOG.info("Baseline comparison written: %s", args.out_json)


if __name__ == "__main__":
  main()
