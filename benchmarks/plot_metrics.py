#!/usr/bin/env python3
import argparse
import csv
import math
import pathlib
from collections import defaultdict


def load_rows(csv_path: pathlib.Path):
  rows = []
  with csv_path.open(newline="") as f:
    reader = csv.DictReader(f)
    for r in reader:
      rows.append(r)
  return rows


def _svg_header(w: int, h: int) -> str:
  return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">'


def _svg_footer() -> str:
  return "</svg>\n"


def _write_svg(path: pathlib.Path, lines):
  path.write_text("\n".join(lines) + "\n")


def _linspace(start: float, end: float, steps: int):
  if steps <= 1:
    return [start]
  step = (end - start) / (steps - 1)
  return [start + i * step for i in range(steps)]


def _draw_axes_and_ticks(svg_lines, left, top, plot_w, plot_h, x_ticks, y_ticks, sx, sy, xlabel, ylabel):
  svg_lines.append(f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+plot_h}" stroke="#334155" stroke-width="2"/>')
  svg_lines.append(f'<line x1="{left}" y1="{top+plot_h}" x2="{left+plot_w}" y2="{top+plot_h}" stroke="#334155" stroke-width="2"/>')
  for xv in x_ticks:
    x = sx(xv)
    svg_lines.append(f'<line x1="{x:.2f}" y1="{top+plot_h}" x2="{x:.2f}" y2="{top+plot_h+6}" stroke="#64748b"/>')
    svg_lines.append(f'<text x="{x:.2f}" y="{top+plot_h+22}" text-anchor="middle" font-size="11" fill="#475569">{xv:.2f}</text>')
  for yv in y_ticks:
    y = sy(yv)
    svg_lines.append(f'<line x1="{left-6}" y1="{y:.2f}" x2="{left}" y2="{y:.2f}" stroke="#64748b"/>')
    svg_lines.append(f'<text x="{left-10}" y="{y+4:.2f}" text-anchor="end" font-size="11" fill="#475569">{yv:.2f}</text>')
    svg_lines.append(f'<line x1="{left}" y1="{y:.2f}" x2="{left+plot_w}" y2="{y:.2f}" stroke="#e2e8f0" stroke-dasharray="2,2"/>')
  svg_lines.append(f'<text x="{left + plot_w/2:.2f}" y="{top+plot_h+42}" text-anchor="middle" font-size="13" fill="#334155">{xlabel}</text>')
  svg_lines.append(f'<text x="20" y="{top + plot_h/2:.2f}" transform="rotate(-90 20 {top + plot_h/2:.2f})" font-size="13" fill="#334155">{ylabel}</text>')


def write_bar_chart(path: pathlib.Path, title: str, values, y_label: str, color: str):
  w, h = 980, 520
  left, right, top, bottom = 90, 40, 70, 100
  plot_w = w - left - right
  plot_h = h - top - bottom
  n = max(len(values), 1)
  xvals = list(range(1, n + 1))
  vmax = max(values) if values else 1.0
  vmax = vmax if vmax > 0 else 1.0
  y_max = vmax * 1.15
  y_min = 0.0

  def sx(v):
    return left + ((v - 0.5) / n) * plot_w

  def sy(v):
    return top + plot_h - ((v - y_min) / max(y_max - y_min, 1e-9)) * plot_h

  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="35" text-anchor="middle" font-size="20" fill="#111827">{title}</text>')
  _draw_axes_and_ticks(
    s, left, top, plot_w, plot_h,
    _linspace(1, n, min(n, 6)),
    _linspace(y_min, y_max, 6),
    sx, sy, "Run index", y_label
  )

  bw = plot_w / n * 0.72
  for i, v in enumerate(values):
    cx = sx(i + 1)
    x = cx - bw / 2
    y = sy(v)
    bh = sy(0.0) - y
    s.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{bw:.2f}" height="{bh:.2f}" fill="{color}" opacity="0.90"/>')
  s.append(_svg_footer())
  _write_svg(path, s)


def write_scatter(path: pathlib.Path, title: str, xvals, yvals, xlabel: str, ylabel: str):
  w, h = 980, 520
  left, right, top, bottom = 100, 50, 70, 90
  plot_w = w - left - right
  plot_h = h - top - bottom
  xmin = min(xvals) if xvals else 0.0
  xmax = max(xvals) if xvals else 1.0
  ymin = min(yvals) if yvals else 0.0
  ymax = max(yvals) if yvals else 1.0
  if xmax == xmin:
    xmax += 1.0
  if ymax == ymin:
    ymax += 1.0
  xpad = (xmax - xmin) * 0.1
  ypad = (ymax - ymin) * 0.1
  xmin -= xpad
  xmax += xpad
  ymin -= ypad
  ymax += ypad

  def sx(v):
    return left + (v - xmin) / (xmax - xmin) * plot_w

  def sy(v):
    return top + plot_h - (v - ymin) / (ymax - ymin) * plot_h

  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="35" text-anchor="middle" font-size="20" fill="#111827">{title}</text>')
  _draw_axes_and_ticks(
    s, left, top, plot_w, plot_h,
    _linspace(xmin, xmax, 6),
    _linspace(ymin, ymax, 6),
    sx, sy, xlabel, ylabel
  )
  for x, y in zip(xvals, yvals):
    s.append(f'<circle cx="{sx(x):.2f}" cy="{sy(y):.2f}" r="5" fill="#0ea5e9" opacity="0.85"/>')
  s.append(_svg_footer())
  _write_svg(path, s)


def write_line_chart(path: pathlib.Path, title: str, xvals, yvals, xlabel: str, ylabel: str, color: str):
  w, h = 980, 520
  left, right, top, bottom = 100, 50, 70, 90
  plot_w = w - left - right
  plot_h = h - top - bottom
  xmin = min(xvals) if xvals else 0.0
  xmax = max(xvals) if xvals else 1.0
  ymin = min(yvals) if yvals else 0.0
  ymax = max(yvals) if yvals else 1.0
  if xmax == xmin:
    xmax += 1.0
  if ymax == ymin:
    ymax += 1.0
  ypad = (ymax - ymin) * 0.12
  ymin -= ypad
  ymax += ypad

  def sx(v):
    return left + (v - xmin) / (xmax - xmin) * plot_w

  def sy(v):
    return top + plot_h - (v - ymin) / (ymax - ymin) * plot_h

  pts = " ".join(f"{sx(x):.2f},{sy(y):.2f}" for x, y in zip(xvals, yvals))
  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="35" text-anchor="middle" font-size="20" fill="#111827">{title}</text>')
  _draw_axes_and_ticks(
    s, left, top, plot_w, plot_h,
    _linspace(xmin, xmax, 6),
    _linspace(ymin, ymax, 6),
    sx, sy, xlabel, ylabel
  )
  s.append(f'<polyline fill="none" stroke="{color}" stroke-width="3" points="{pts}"/>')
  for x, y in zip(xvals, yvals):
    s.append(f'<circle cx="{sx(x):.2f}" cy="{sy(y):.2f}" r="4" fill="{color}"/>')
  s.append(_svg_footer())
  _write_svg(path, s)


def write_histogram(path: pathlib.Path, title: str, values, bins: int, xlabel: str):
  w, h = 980, 520
  left, right, top, bottom = 100, 50, 70, 90
  plot_w = w - left - right
  plot_h = h - top - bottom
  vmin = min(values) if values else 0.0
  vmax = max(values) if values else 1.0
  if vmax == vmin:
    vmax += 1.0
  step = (vmax - vmin) / bins
  counts = [0 for _ in range(bins)]
  for v in values:
    idx = int((v - vmin) / step)
    if idx >= bins:
      idx = bins - 1
    counts[idx] += 1
  maxc = max(counts) if counts else 1
  maxc = max(maxc, 1)

  def sx(v):
    return left + (v - vmin) / (vmax - vmin) * plot_w

  def sy(v):
    return top + plot_h - (v / maxc) * plot_h

  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="35" text-anchor="middle" font-size="20" fill="#111827">{title}</text>')
  _draw_axes_and_ticks(
    s, left, top, plot_w, plot_h,
    _linspace(vmin, vmax, 6),
    _linspace(0, maxc, 6),
    sx, sy, xlabel, "Count"
  )
  for i, c in enumerate(counts):
    x0 = vmin + i * step
    x1 = x0 + step
    px0 = sx(x0) + 1
    pw = max(sx(x1) - sx(x0) - 2, 1)
    py = sy(c)
    ph = sy(0) - py
    s.append(f'<rect x="{px0:.2f}" y="{py:.2f}" width="{pw:.2f}" height="{ph:.2f}" fill="#8b5cf6" opacity="0.85"/>')
  s.append(_svg_footer())
  _write_svg(path, s)


def write_density(path: pathlib.Path, title: str, values, xlabel: str):
  w, h = 980, 520
  left, right, top, bottom = 100, 50, 70, 90
  plot_w = w - left - right
  plot_h = h - top - bottom
  if not values:
    values = [0.0]
  vmin = min(values)
  vmax = max(values)
  if vmax == vmin:
    vmax += 1.0

  mu = sum(values) / len(values)
  std = math.sqrt(sum((v - mu) ** 2 for v in values) / len(values))
  bw = std * (4 / (3 * len(values))) ** 0.2 if std > 0 else (vmax - vmin) / 8
  bw = max(bw, 1e-3)

  xs = _linspace(vmin, vmax, 100)
  ys = []
  norm = 1 / (len(values) * bw * math.sqrt(2 * math.pi))
  for x in xs:
    s = 0.0
    for v in values:
      z = (x - v) / bw
      s += math.exp(-0.5 * z * z)
    ys.append(norm * s)
  ymin = 0.0
  ymax = max(ys) if ys else 1.0
  ymax = max(ymax, 1e-6)

  def sx(v):
    return left + (v - vmin) / (vmax - vmin) * plot_w

  def sy(v):
    return top + plot_h - (v - ymin) / (ymax - ymin) * plot_h

  pts = " ".join(f"{sx(x):.2f},{sy(y):.2f}" for x, y in zip(xs, ys))
  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="35" text-anchor="middle" font-size="20" fill="#111827">{title}</text>')
  _draw_axes_and_ticks(
    s, left, top, plot_w, plot_h,
    _linspace(vmin, vmax, 6),
    _linspace(ymin, ymax, 6),
    sx, sy, xlabel, "Density"
  )
  s.append(f'<polyline fill="none" stroke="#1d4ed8" stroke-width="3" points="{pts}"/>')
  s.append(_svg_footer())
  _write_svg(path, s)


def write_heatmap(path: pathlib.Path, title: str, rows, cols, values, xlabel: str, ylabel: str):
  w, h = 920, 620
  left, right, top, bottom = 120, 30, 80, 100
  plot_w = w - left - right
  plot_h = h - top - bottom
  rvals = sorted(set(rows))
  cvals = sorted(set(cols))
  if not rvals or not cvals:
    _write_svg(path, [_svg_header(w, h), '<text x="20" y="20">No data</text>', _svg_footer()])
    return
  grid = defaultdict(list)
  for r, c, v in zip(rows, cols, values):
    grid[(r, c)].append(v)
  cell_w = plot_w / len(cvals)
  cell_h = plot_h / len(rvals)
  avg_map = {}
  for r in rvals:
    for c in cvals:
      vals = grid.get((r, c), [])
      avg_map[(r, c)] = sum(vals) / len(vals) if vals else 0.0
  allv = list(avg_map.values())
  vmin = min(allv) if allv else 0.0
  vmax = max(allv) if allv else 1.0
  if vmax == vmin:
    vmax += 1.0

  def color(v):
    t = (v - vmin) / (vmax - vmin)
    r = int(30 + 200 * t)
    g = int(80 + 120 * (1 - t))
    b = int(180 - 120 * t)
    return f"rgb({r},{g},{b})"

  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="40" text-anchor="middle" font-size="20" fill="#111827">{title}</text>')

  for i, r in enumerate(rvals):
    for j, c in enumerate(cvals):
      x = left + j * cell_w
      y = top + i * cell_h
      v = avg_map[(r, c)]
      s.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{cell_w:.2f}" height="{cell_h:.2f}" fill="{color(v)}" stroke="#e2e8f0"/>')
      s.append(f'<text x="{x + cell_w/2:.2f}" y="{y + cell_h/2 + 4:.2f}" text-anchor="middle" font-size="10" fill="#f8fafc">{v:.1f}</text>')

  for i, r in enumerate(rvals):
    y = top + i * cell_h + cell_h / 2
    s.append(f'<text x="{left-12}" y="{y+4:.2f}" text-anchor="end" font-size="11" fill="#334155">{r}</text>')
  for j, c in enumerate(cvals):
    x = left + j * cell_w + cell_w / 2
    s.append(f'<text x="{x:.2f}" y="{top+plot_h+20}" text-anchor="middle" font-size="11" fill="#334155">{c}</text>')
  s.append(f'<text x="{left + plot_w/2:.2f}" y="{h-20}" text-anchor="middle" font-size="13" fill="#334155">{xlabel}</text>')
  s.append(f'<text x="24" y="{top + plot_h/2:.2f}" transform="rotate(-90 24 {top + plot_h/2:.2f})" font-size="13" fill="#334155">{ylabel}</text>')
  s.append(_svg_footer())
  _write_svg(path, s)


def write_operation_trace(path: pathlib.Path, names, latencies):
  w, h = 1100, max(420, 120 + 24 * len(names))
  left, right, top, bottom = 220, 40, 70, 60
  plot_w = w - left - right
  plot_h = h - top - bottom
  max_lat = max(latencies) if latencies else 1.0

  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="35" text-anchor="middle" font-size="20" fill="#111827">Operation Trace (Load / Compute / Store)</text>')

  for i, (name, lat) in enumerate(zip(names, latencies)):
    y = top + i * (plot_h / max(len(names), 1))
    bh = max((plot_h / max(len(names), 1)) - 5, 6)
    load = 0.22 * lat
    compute = 0.63 * lat
    store = 0.15 * lat
    x0 = left
    scale = plot_w / max_lat
    wl = load * scale
    wc = compute * scale
    ws = store * scale
    s.append(f'<text x="{left-8}" y="{y+bh-2:.2f}" text-anchor="end" font-size="10" fill="#334155">{name}</text>')
    s.append(f'<rect x="{x0:.2f}" y="{y:.2f}" width="{wl:.2f}" height="{bh:.2f}" fill="#38bdf8"/>')
    s.append(f'<rect x="{x0+wl:.2f}" y="{y:.2f}" width="{wc:.2f}" height="{bh:.2f}" fill="#2563eb"/>')
    s.append(f'<rect x="{x0+wl+wc:.2f}" y="{y:.2f}" width="{ws:.2f}" height="{bh:.2f}" fill="#f59e0b"/>')

  s.append(f'<rect x="{left}" y="{h-45}" width="14" height="10" fill="#38bdf8"/><text x="{left+20}" y="{h-36}" font-size="11">Load</text>')
  s.append(f'<rect x="{left+90}" y="{h-45}" width="14" height="10" fill="#2563eb"/><text x="{left+110}" y="{h-36}" font-size="11">Compute</text>')
  s.append(f'<rect x="{left+200}" y="{h-45}" width="14" height="10" fill="#f59e0b"/><text x="{left+220}" y="{h-36}" font-size="11">Store</text>')
  s.append(_svg_footer())
  _write_svg(path, s)


def main() -> None:
  parser = argparse.ArgumentParser()
  parser.add_argument("--input", required=True, help="Input metrics CSV path")
  parser.add_argument("--out-dir", required=True, help="Output directory for charts")
  args = parser.parse_args()

  in_path = pathlib.Path(args.input)
  out_dir = pathlib.Path(args.out_dir)
  out_dir.mkdir(parents=True, exist_ok=True)

  rows = load_rows(in_path)
  if not rows:
    (out_dir / "plots.txt").write_text("No metrics available to plot.\n")
    return

  names = [r["name"] for r in rows]
  idx = list(range(1, len(rows) + 1))
  lat = [float(r["latency_cycles"]) for r in rows]
  thr = [float(r["throughput_ops_per_cycle"]) for r in rows]
  eff = [float(r["efficiency"]) for r in rows]
  bw = [float(r["bandwidth_utilization"]) for r in rows]
  kvals = [float(r["k"]) for r in rows]
  row_vals = [int(float(r["rows"])) for r in rows]
  col_vals = [int(float(r["cols"])) for r in rows]

  write_bar_chart(out_dir / "throughput_by_config.svg", "Throughput by run index", thr, "Ops per cycle", "#0ea5e9")
  write_bar_chart(out_dir / "latency_by_config.svg", "Latency by run index", lat, "Cycles", "#ef4444")
  write_scatter(out_dir / "efficiency_vs_bandwidth.svg", "Efficiency vs bandwidth utilization", bw, eff, "Bandwidth utilization", "Efficiency")

  order = sorted(range(len(rows)), key=lambda i: kvals[i])
  k_sorted = [kvals[i] for i in order]
  thr_sorted = [thr[i] for i in order]
  lat_sorted = [lat[i] for i in order]
  write_line_chart(out_dir / "throughput_vs_k_line.svg", "Throughput vs K dimension", k_sorted, thr_sorted, "K", "Throughput (ops/cycle)", "#2563eb")
  write_line_chart(out_dir / "latency_vs_k_line.svg", "Latency vs K dimension", k_sorted, lat_sorted, "K", "Latency (cycles)", "#dc2626")

  write_histogram(out_dir / "throughput_histogram.svg", "Throughput distribution", thr, bins=8, xlabel="Throughput (ops/cycle)")
  write_histogram(out_dir / "latency_histogram.svg", "Latency distribution", lat, bins=8, xlabel="Latency (cycles)")
  write_density(out_dir / "efficiency_density.svg", "Efficiency density estimate", eff, xlabel="Efficiency")
  write_scatter(out_dir / "throughput_vs_latency_scatter.svg", "Throughput vs latency", lat, thr, "Latency (cycles)", "Throughput (ops/cycle)")
  write_heatmap(out_dir / "throughput_heatmap_rows_cols.svg", "Throughput heatmap (rows x cols)", row_vals, col_vals, thr, "Columns", "Rows")
  write_operation_trace(out_dir / "operation_trace.svg", names, lat)
  print(f"Charts generated in: {out_dir}")


if __name__ == "__main__":
  main()
