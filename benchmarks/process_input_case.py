#!/usr/bin/env python3
import argparse
import csv
import json
import pathlib
import subprocess
import random

from benchmark_runner import parse_metrics
from logging_utils import get_logger

LOG = get_logger("process_input_case")


def load_matrix_csv(path: pathlib.Path):
  matrix = []
  with path.open(newline="") as f:
    reader = csv.reader(f)
    for row in reader:
      if not row:
        continue
      matrix.append([float(x) for x in row])
  return matrix


def gen_matrix(rows: int, cols: int, low: int, high: int, seed: int):
  rng = random.Random(seed)
  return [[float(rng.randint(low, high)) for _ in range(cols)] for _ in range(rows)]


def matmul(a, b):
  m = len(a)
  k = len(a[0])
  n = len(b[0])
  out = [[0.0 for _ in range(n)] for _ in range(m)]
  for i in range(m):
    for j in range(n):
      s = 0.0
      for t in range(k):
        s += a[i][t] * b[t][j]
      out[i][j] = s
  return out


def save_matrix_csv(path: pathlib.Path, matrix):
  with path.open("w", newline="") as f:
    writer = csv.writer(f)
    for row in matrix:
      writer.writerow(row)


def _svg_header(w: int, h: int) -> str:
  return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'


def _svg_footer() -> str:
  return "</svg>\n"


def plot_output_heatmap(path: pathlib.Path, matrix, title: str):
  rows = len(matrix)
  cols = len(matrix[0]) if rows else 0
  w, h = 860, 580
  left, right, top, bottom = 110, 30, 70, 80
  plot_w = w - left - right
  plot_h = h - top - bottom
  cell_w = plot_w / max(cols, 1)
  cell_h = plot_h / max(rows, 1)

  vals = [v for r in matrix for v in r]
  vmin = min(vals) if vals else 0.0
  vmax = max(vals) if vals else 1.0
  if vmax == vmin:
    vmax += 1.0

  def color(v):
    # Simple orange-red gradient for portability.
    t = (v - vmin) / (vmax - vmin)
    r = int(240 * t + 20)
    g = int(180 * (1 - t) + 20)
    b = int(90 * (1 - t) + 20)
    return f"rgb({r},{g},{b})"

  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="35" text-anchor="middle" font-size="20" fill="#222">{title}</text>')

  for i in range(rows):
    for j in range(cols):
      x = left + j * cell_w
      y = top + i * cell_h
      s.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{cell_w:.2f}" height="{cell_h:.2f}" fill="{color(matrix[i][j])}" stroke="#fff"/>')
      s.append(f'<text x="{x + cell_w/2:.2f}" y="{y + cell_h/2 + 4:.2f}" text-anchor="middle" font-size="10" fill="#111">{matrix[i][j]:.1f}</text>')

  s.append(f'<text x="{left + plot_w/2}" y="{h-18}" text-anchor="middle" font-size="13" fill="#333">Output column</text>')
  s.append(f'<text x="25" y="{top + plot_h/2}" transform="rotate(-90 25 {top + plot_h/2})" font-size="13" fill="#333">Output row</text>')
  s.append(_svg_footer())
  path.write_text("\n".join(s) + "\n")


def plot_metric_bars(path: pathlib.Path, metrics: dict):
  labels = [
    "latency_cycles",
    "throughput_ops_per_cycle",
    "efficiency",
    "bandwidth_utilization",
    "pipeline_depth",
  ]
  values = [float(metrics.get(k, 0.0)) for k in labels]
  w, h = 920, 460
  left, right, top, bottom = 70, 30, 60, 110
  plot_w = w - left - right
  plot_h = h - top - bottom
  vmax = max(values) if values else 1.0
  vmax = vmax if vmax > 0 else 1.0
  bar_w = plot_w / max(len(values), 1)
  colors = ["#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"]

  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="30" text-anchor="middle" font-size="20" fill="#222">Input-case accelerator metrics</text>')
  s.append(f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+plot_h}" stroke="#444" stroke-width="2"/>')
  s.append(f'<line x1="{left}" y1="{top+plot_h}" x2="{left+plot_w}" y2="{top+plot_h}" stroke="#444" stroke-width="2"/>')

  for i, (label, val) in enumerate(zip(labels, values)):
    bh = (val / vmax) * (plot_h - 10)
    x = left + i * bar_w + 10
    y = top + plot_h - bh
    bw = max(bar_w - 20, 8)
    s.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{bw:.2f}" height="{bh:.2f}" fill="{colors[i % len(colors)]}" opacity="0.9"/>')
    s.append(f'<text x="{x + bw/2:.2f}" y="{top + plot_h + 17}" text-anchor="middle" font-size="10" fill="#222">{label}</text>')
    s.append(f'<text x="{x + bw/2:.2f}" y="{y - 6:.2f}" text-anchor="middle" font-size="10" fill="#111">{val:.3g}</text>')

  s.append(_svg_footer())
  path.write_text("\n".join(s) + "\n")


def main() -> None:
  parser = argparse.ArgumentParser()
  parser.add_argument("--config", required=True, help="Input case JSON config path")
  parser.add_argument("--out-dir", required=True, help="Output directory")
  parser.add_argument("--rows", type=int, help="Override rows for generated input")
  parser.add_argument("--cols", type=int, help="Override cols for generated input")
  parser.add_argument("--k", type=int, help="Override k for generated input")
  parser.add_argument("--seed", type=int, default=11, help="Seed for generated input")
  args = parser.parse_args()

  cfg = json.loads(pathlib.Path(args.config).read_text())
  LOG.info("Processing input case config: %s", args.config)
  root = pathlib.Path(__file__).resolve().parent.parent
  out_dir = pathlib.Path(args.out_dir)
  out_dir.mkdir(parents=True, exist_ok=True)

  case_name = cfg.get("name", "input_case")
  warmup = int(cfg.get("warmup", 4))
  maxbw = int(cfg.get("maxbw", 64))
  mode = cfg.get("mode", "csv")

  if mode == "generated":
    m = int(args.rows or cfg.get("rows", 4))
    n = int(args.cols or cfg.get("cols", 4))
    k = int(args.k or cfg.get("k", 4))
    val_low = int(cfg.get("value_low", -3))
    val_high = int(cfg.get("value_high", 6))
    a = gen_matrix(m, k, val_low, val_high, args.seed)
    b = gen_matrix(k, n, val_low, val_high, args.seed + 1)
  else:
    a_path = root / cfg["matrix_a_csv"]
    b_path = root / cfg["matrix_b_csv"]
    a = load_matrix_csv(a_path)
    b = load_matrix_csv(b_path)

  if not a or not b:
    raise ValueError("Input matrices must be non-empty.")
  if len(a[0]) != len(b):
    raise ValueError("Matrix dimensions do not match for multiplication.")

  m = len(a)
  k = len(a[0])
  n = len(b[0])

  c = matmul(a, b)
  output_csv = out_dir / f"{case_name}_output.csv"
  save_matrix_csv(output_csv, c)

  sim_log = out_dir / f"{case_name}.log"
  run_cmd = [
    str(root / "scripts" / "run_config.sh"),
    str(m),
    str(n),
    str(k),
    str(warmup),
    str(maxbw),
    str(sim_log),
  ]
  subprocess.run(run_cmd, cwd=root, check=True)
  LOG.debug("Simulation log generated at %s", sim_log)

  metrics = parse_metrics(sim_log)
  metrics["name"] = case_name
  metrics["rows"] = m
  metrics["cols"] = n
  metrics["k"] = k
  metrics["output_csv"] = str(output_csv)

  (out_dir / f"{case_name}_metrics.json").write_text(json.dumps(metrics, indent=2))
  with (out_dir / f"{case_name}_metrics.csv").open("w", newline="") as f:
    writer = csv.writer(f)
    writer.writerow(["metric", "value"])
    for key in ["latency_cycles", "throughput_ops_per_cycle", "efficiency", "bandwidth_utilization", "pipeline_depth", "total_mac_ops"]:
      writer.writerow([key, metrics.get(key, "")])

  plot_output_heatmap(out_dir / f"{case_name}_output_heatmap.svg", c, f"Output heatmap: {case_name}")
  plot_metric_bars(out_dir / f"{case_name}_metrics_chart.svg", metrics)

  summary = [
    f"# Input Case Summary: {case_name}",
    "",
    f"- Matrix A: {m}x{k}",
    f"- Matrix B: {k}x{n}",
    f"- Output CSV: `{output_csv.name}`",
    f"- Simulation Log: `{sim_log.name}`",
    "",
    "## Metrics",
    f"- Latency (cycles): {metrics.get('latency_cycles')}",
    f"- Throughput (ops/cycle): {metrics.get('throughput_ops_per_cycle')}",
    f"- Efficiency: {metrics.get('efficiency')}",
    f"- Bandwidth utilization: {metrics.get('bandwidth_utilization')}",
    f"- Pipeline depth: {metrics.get('pipeline_depth')}",
    "",
    "## Visuals",
    f"- Output heatmap: `{case_name}_output_heatmap.svg`",
    f"- Metric chart: `{case_name}_metrics_chart.svg`",
  ]
  (out_dir / f"{case_name}_summary.md").write_text("\n".join(summary) + "\n")
  LOG.info("Input case processed. Artifacts in: %s", out_dir)


if __name__ == "__main__":
  main()
