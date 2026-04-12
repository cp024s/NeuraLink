#!/usr/bin/env python3
import argparse
import csv
import json
import pathlib
import re
import subprocess
import random
from itertools import product
from datetime import datetime

from logging_utils import get_logger

METRIC_RE = re.compile(r"^METRIC\s+([a-zA-Z0-9_]+)=(.+)$")
LOG = get_logger("benchmark_runner")


def parse_metrics(log_path: pathlib.Path) -> dict:
  metrics = {}
  for line in log_path.read_text().splitlines():
    match = METRIC_RE.match(line.strip())
    if not match:
      continue
    key = match.group(1)
    raw_val = match.group(2)
    try:
      if "." in raw_val:
        metrics[key] = float(raw_val)
      else:
        metrics[key] = int(raw_val)
    except ValueError:
      metrics[key] = raw_val
  return metrics


def run_single(root: pathlib.Path, out_dir: pathlib.Path, cfg: dict) -> dict:
  run_name = cfg["name"]
  log_path = out_dir / f"{run_name}.log"

  op_type = cfg.get("op_type", "gemm")
  op_map = {
    "gemm": 0,
    "vector": 1,
    "conv2d": 2,
    "depthwise_conv": 3,
    "pooling": 4,
    "normalization": 5,
    "reduction": 6,
    "attention_qkv": 7,
    "math": 8,
  }
  op_class = int(cfg.get("op_class", op_map.get(op_type, 0)))

  cmd = [
    str(root / "scripts" / "run_config.sh"),
    str(cfg["rows"]),
    str(cfg["cols"]),
    str(cfg["k"]),
    str(cfg.get("warmup", 4)),
    str(cfg.get("maxbw", 64)),
    str(log_path),
    str(op_class),
  ]
  subprocess.run(cmd, cwd=root, check=True)
  LOG.debug("Completed run '%s' log=%s", run_name, log_path)

  metrics = parse_metrics(log_path)
  latency_mult = float(cfg.get("latency_mult", 1.0))
  throughput_mult = float(cfg.get("throughput_mult", 1.0))
  efficiency_mult = float(cfg.get("efficiency_mult", 1.0))

  if "latency_cycles" in metrics:
    metrics["sim_latency_cycles"] = metrics["latency_cycles"]
    metrics["latency_cycles"] = round(float(metrics["latency_cycles"]) * latency_mult, 6)
  if "throughput_ops_per_cycle" in metrics:
    metrics["sim_throughput_ops_per_cycle"] = metrics["throughput_ops_per_cycle"]
    metrics["throughput_ops_per_cycle"] = round(float(metrics["throughput_ops_per_cycle"]) * throughput_mult, 6)
  if "efficiency" in metrics:
    metrics["sim_efficiency"] = metrics["efficiency"]
    metrics["efficiency"] = round(float(metrics["efficiency"]) * efficiency_mult, 6)

  metrics["name"] = run_name
  metrics["rows"] = cfg["rows"]
  metrics["cols"] = cfg["cols"]
  metrics["k"] = cfg["k"]
  metrics["op_type"] = op_type
  metrics["op_class"] = op_class
  metrics["timestamp"] = datetime.utcnow().isoformat() + "Z"
  return metrics


def parse_int_list(raw: str) -> list[int]:
  values = []
  for tok in raw.split(","):
    tok = tok.strip()
    if not tok:
      continue
    values.append(int(tok))
  return values


def build_runs_from_args(args) -> list[dict]:
  if args.config:
    config_data = json.loads(pathlib.Path(args.config).read_text())
    return config_data["runs"]

  rows = parse_int_list(args.rows_list)
  cols = parse_int_list(args.cols_list)
  ks = parse_int_list(args.k_list)

  if not rows or not cols or not ks:
    raise ValueError("rows-list, cols-list, and k-list must be non-empty.")

  base_runs = []
  idx = 0
  for r, c, k in product(rows, cols, ks):
    idx += 1
    base_runs.append({
      "name": f"grid_{idx:03d}_r{r}_c{c}_k{k}",
      "rows": r,
      "cols": c,
      "k": k,
      "warmup": args.warmup,
      "maxbw": args.maxbw
    })

  if args.random_samples <= 0:
    return base_runs

  rng = random.Random(args.seed)
  sampled = []
  for i in range(args.random_samples):
    r = rng.choice(rows)
    c = rng.choice(cols)
    k = rng.choice(ks)
    sampled.append({
      "name": f"rnd_{i+1:03d}_r{r}_c{c}_k{k}",
      "rows": r,
      "cols": c,
      "k": k,
      "warmup": args.warmup,
      "maxbw": args.maxbw
    })
  return base_runs + sampled


def main() -> None:
  parser = argparse.ArgumentParser()
  parser.add_argument("--config", help="Path to JSON config file")
  parser.add_argument("--rows-list", default="4,8,12", help="Comma separated rows list")
  parser.add_argument("--cols-list", default="4,8,12", help="Comma separated cols list")
  parser.add_argument("--k-list", default="16,32,64", help="Comma separated k list")
  parser.add_argument("--warmup", type=int, default=4, help="Warmup cycles")
  parser.add_argument("--maxbw", type=int, default=64, help="Max BW bytes/cycle")
  parser.add_argument("--random-samples", type=int, default=0, help="Extra random samples")
  parser.add_argument("--seed", type=int, default=7, help="Random seed for sampling")
  parser.add_argument("--out-dir", required=True, help="Directory for outputs")
  parser.add_argument("--meta", default="", help="Optional run metadata string")
  args = parser.parse_args()

  root = pathlib.Path(__file__).resolve().parent.parent
  out_dir = pathlib.Path(args.out_dir)
  out_dir.mkdir(parents=True, exist_ok=True)

  runs = build_runs_from_args(args)
  LOG.info("Starting benchmark sweep with %d runs", len(runs))

  results = []
  for run_cfg in runs:
    LOG.info("Running config: %s (r=%s c=%s k=%s)", run_cfg["name"], run_cfg["rows"], run_cfg["cols"], run_cfg["k"])
    result = run_single(root, out_dir, run_cfg)
    result["run_meta"] = args.meta
    results.append(result)

  json_path = out_dir / "metrics.json"
  json_path.write_text(json.dumps(results, indent=2))

  if results:
    ordered_keys = [
      "name",
      "rows",
      "cols",
      "k",
      "op_type",
      "op_class",
      "latency_cycles",
      "throughput_ops_per_cycle",
      "efficiency",
      "bandwidth_utilization",
      "pipeline_depth",
      "total_mac_ops",
      "sim_latency_cycles",
      "sim_throughput_ops_per_cycle",
      "sim_efficiency",
      "run_meta",
      "timestamp",
    ]
    csv_path = out_dir / "metrics.csv"
    with csv_path.open("w", newline="") as f:
      writer = csv.DictWriter(f, fieldnames=ordered_keys)
      writer.writeheader()
      for row in results:
        writer.writerow({k: row.get(k, "") for k in ordered_keys})

  LOG.info("Wrote benchmark results to: %s", out_dir)


if __name__ == "__main__":
  main()
