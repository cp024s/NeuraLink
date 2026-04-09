#!/usr/bin/env python3
import argparse
import csv
import pathlib
from statistics import mean


def main() -> None:
  parser = argparse.ArgumentParser()
  parser.add_argument("--input", required=True, help="Input CSV metrics")
  parser.add_argument("--output", required=True, help="Output markdown summary")
  args = parser.parse_args()

  rows = []
  with open(args.input, newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
      rows.append(row)

  if not rows:
    pathlib.Path(args.output).write_text("# Benchmark Summary\n\nNo runs found.\n")
    return

  latencies = [float(r["latency_cycles"]) for r in rows]
  throughputs = [float(r["throughput_ops_per_cycle"]) for r in rows]
  efficiencies = [float(r["efficiency"]) for r in rows]
  bandwidths = [float(r["bandwidth_utilization"]) for r in rows]
  pipelines = [int(float(r["pipeline_depth"])) for r in rows]

  best_tp = max(rows, key=lambda r: float(r["throughput_ops_per_cycle"]))
  best_eff = max(rows, key=lambda r: float(r["efficiency"]))
  lowest_lat = min(rows, key=lambda r: float(r["latency_cycles"]))

  md = []
  md.append("# Benchmark Summary")
  md.append("")
  md.append("## Aggregate")
  md.append(f"- Runs: {len(rows)}")
  md.append(f"- Avg latency (cycles): {mean(latencies):.2f}")
  md.append(f"- Avg throughput (ops/cycle): {mean(throughputs):.2f}")
  md.append(f"- Avg efficiency: {mean(efficiencies):.4f}")
  md.append(f"- Avg bandwidth utilization: {mean(bandwidths):.4f}")
  md.append(f"- Pipeline depth (reported): min={min(pipelines)}, max={max(pipelines)}")
  md.append("")
  md.append("## Best Cases")
  md.append(
    f"- Lowest latency: `{lowest_lat['name']}` -> {lowest_lat['latency_cycles']} cycles"
  )
  md.append(
    f"- Highest throughput: `{best_tp['name']}` -> {best_tp['throughput_ops_per_cycle']} ops/cycle"
  )
  md.append(
    f"- Highest efficiency: `{best_eff['name']}` -> {best_eff['efficiency']}"
  )
  md.append("")
  md.append("## Run Table")
  md.append("")
  md.append("| name | rows | cols | k | latency | throughput | efficiency | bw_util | pipe_depth |")
  md.append("|---|---:|---:|---:|---:|---:|---:|---:|---:|")
  for r in rows:
    md.append(
      "| {name} | {rows} | {cols} | {k} | {latency_cycles} | {throughput_ops_per_cycle} | {efficiency} | {bandwidth_utilization} | {pipeline_depth} |".format(
        **r
      )
    )

  pathlib.Path(args.output).write_text("\n".join(md) + "\n")


if __name__ == "__main__":
  main()
