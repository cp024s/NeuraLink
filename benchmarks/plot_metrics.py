#!/usr/bin/env python3
import argparse
import csv
import pathlib


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


def write_bar_chart(path: pathlib.Path, title: str, names, values, y_label: str, color: str):
  w, h = 980, 520
  left, right, top, bottom = 90, 40, 70, 100
  plot_w = w - left - right
  plot_h = h - top - bottom
  vmax = max(values) if values else 1.0
  vmax = vmax if vmax > 0 else 1.0
  bar_w = plot_w / max(len(values), 1)

  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="35" text-anchor="middle" font-size="20" fill="#222">{title}</text>')
  s.append(f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+plot_h}" stroke="#444" stroke-width="2"/>')
  s.append(f'<line x1="{left}" y1="{top+plot_h}" x2="{left+plot_w}" y2="{top+plot_h}" stroke="#444" stroke-width="2"/>')
  s.append(f'<text x="18" y="{top + plot_h/2}" transform="rotate(-90 18 {top + plot_h/2})" font-size="13" fill="#333">{y_label}</text>')

  for i, (n, v) in enumerate(zip(names, values)):
    bh = (v / vmax) * (plot_h - 10)
    x = left + i * bar_w + 12
    y = top + plot_h - bh
    bw = max(bar_w - 24, 8)
    s.append(f'<rect x="{x:.2f}" y="{y:.2f}" width="{bw:.2f}" height="{bh:.2f}" fill="{color}" opacity="0.88"/>')
    s.append(f'<text x="{x + bw/2:.2f}" y="{top + plot_h + 18}" text-anchor="middle" font-size="11" fill="#333">{n}</text>')
    s.append(f'<text x="{x + bw/2:.2f}" y="{y - 6:.2f}" text-anchor="middle" font-size="11" fill="#111">{v:.3g}</text>')

  s.append(_svg_footer())
  _write_svg(path, s)


def write_scatter(path: pathlib.Path, title: str, xvals, yvals, names, xlabel: str, ylabel: str):
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

  def sx(v):
    return left + (v - xmin) / (xmax - xmin) * plot_w

  def sy(v):
    return top + plot_h - (v - ymin) / (ymax - ymin) * plot_h

  s = [_svg_header(w, h)]
  s.append(f'<rect x="0" y="0" width="{w}" height="{h}" fill="#ffffff"/>')
  s.append(f'<text x="{w/2}" y="35" text-anchor="middle" font-size="20" fill="#222">{title}</text>')
  s.append(f'<line x1="{left}" y1="{top}" x2="{left}" y2="{top+plot_h}" stroke="#444" stroke-width="2"/>')
  s.append(f'<line x1="{left}" y1="{top+plot_h}" x2="{left+plot_w}" y2="{top+plot_h}" stroke="#444" stroke-width="2"/>')
  s.append(f'<text x="{left + plot_w/2}" y="{h-18}" text-anchor="middle" font-size="13" fill="#333">{xlabel}</text>')
  s.append(f'<text x="20" y="{top + plot_h/2}" transform="rotate(-90 20 {top + plot_h/2})" font-size="13" fill="#333">{ylabel}</text>')

  for xv, yv, n in zip(xvals, yvals, names):
    x = sx(xv)
    y = sy(yv)
    s.append(f'<circle cx="{x:.2f}" cy="{y:.2f}" r="6" fill="#2a9d8f"/>')
    s.append(f'<text x="{x + 8:.2f}" y="{y - 8:.2f}" font-size="11" fill="#222">{n}</text>')

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
  lat = [float(r["latency_cycles"]) for r in rows]
  thr = [float(r["throughput_ops_per_cycle"]) for r in rows]
  eff = [float(r["efficiency"]) for r in rows]
  bw = [float(r["bandwidth_utilization"]) for r in rows]

  write_bar_chart(
    out_dir / "throughput_by_config.svg",
    "Throughput by configuration",
    names,
    thr,
    "Ops per cycle",
    "#2a9d8f",
  )
  write_bar_chart(
    out_dir / "latency_by_config.svg",
    "Latency by configuration",
    names,
    lat,
    "Cycles",
    "#e76f51",
  )
  write_scatter(
    out_dir / "efficiency_vs_bandwidth.svg",
    "Efficiency vs bandwidth utilization",
    bw,
    eff,
    names,
    "Bandwidth utilization",
    "Efficiency",
  )
  print(f"Charts generated in: {out_dir}")


if __name__ == "__main__":
  main()
