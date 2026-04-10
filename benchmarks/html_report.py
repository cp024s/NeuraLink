#!/usr/bin/env python3
import argparse
import csv
import json
import pathlib
from statistics import mean, median


SVG_FILES = [
  "throughput_by_config.svg",
  "latency_by_config.svg",
  "efficiency_vs_bandwidth.svg",
  "throughput_vs_k_line.svg",
  "latency_vs_k_line.svg",
  "throughput_histogram.svg",
  "latency_histogram.svg",
  "efficiency_density.svg",
  "throughput_vs_latency_scatter.svg",
  "throughput_heatmap_rows_cols.svg",
  "operation_trace.svg",
]


def load_csv(path: pathlib.Path):
  rows = []
  with path.open(newline="") as f:
    reader = csv.DictReader(f)
    for row in reader:
      rows.append(row)
  return rows


def read_json(path: pathlib.Path, default_obj):
  if not path.exists():
    return default_obj
  try:
    return json.loads(path.read_text())
  except json.JSONDecodeError:
    return default_obj


def float_col(rows, key):
  vals = []
  for r in rows:
    try:
      vals.append(float(r[key]))
    except Exception:
      pass
  return vals


def render_table(rows):
  if not rows:
    return "<p>No data.</p>"
  headers = list(rows[0].keys())
  out = ['<div class="table-wrap"><table class="metrics-table">']
  out.append("<thead><tr>" + "".join(f"<th>{h}</th>" for h in headers) + "</tr></thead>")
  out.append("<tbody>")
  for r in rows:
    out.append("<tr>" + "".join(f"<td>{r.get(h, '')}</td>" for h in headers) + "</tr>")
  out.append("</tbody></table></div>")
  return "\n".join(out)


def render_stats(rows):
  if not rows:
    return "<p>No stats available.</p>"
  lat = float_col(rows, "latency_cycles")
  thr = float_col(rows, "throughput_ops_per_cycle")
  eff = float_col(rows, "efficiency")
  bw = float_col(rows, "bandwidth_utilization")
  return f"""
<div class="stat-grid">
  <div class="stat"><h3>Runs</h3><p>{len(rows)}</p></div>
  <div class="stat"><h3>Avg Latency</h3><p>{mean(lat):.2f} cycles</p></div>
  <div class="stat"><h3>Avg Throughput</h3><p>{mean(thr):.2f} ops/cycle</p></div>
  <div class="stat"><h3>Median Throughput</h3><p>{median(thr):.2f} ops/cycle</p></div>
  <div class="stat"><h3>Avg Efficiency</h3><p>{mean(eff):.4f}</p></div>
  <div class="stat"><h3>Avg BW Utilization</h3><p>{mean(bw):.4f}</p></div>
</div>
"""


def render_comparison(comp):
  comps = comp.get("comparisons", [])
  if not comps:
    return "<p>No baseline comparison generated.</p>"
  cards = []
  for c in comps:
    tone = "better" if c.get("better") else "worse"
    sign = "+" if c.get("delta_pct", 0) >= 0 else ""
    cards.append(
      f"""<div class="compare-card {tone}">
  <h3>{c['metric']}</h3>
  <p>ours: <b>{c['ours']}</b> | baseline: <b>{c['baseline']}</b></p>
  <p>delta: <b>{sign}{c['delta_pct']}%</b> ({'better' if c.get('better') else 'worse'})</p>
</div>"""
    )
  note = comp.get("baseline_note", "")
  name = comp.get("baseline_name", "Baseline")
  return f"""
<p class="muted">Comparison baseline: <b>{name}</b></p>
<p class="muted">{note}</p>
<div class="compare-grid">
  {''.join(cards)}
</div>
"""


def render_capabilities(cap):
  caps = cap.get("capabilities", [])
  if not caps:
    return "<p>No capability matrix found.</p>"
  out = ['<div class="table-wrap"><table class="metrics-table">']
  out.append("<thead><tr><th>Capability</th><th>Status</th><th>Notes</th></tr></thead><tbody>")
  for c in caps:
    status = c.get("status", "")
    if "Implemented" in status:
      cls = "status-impl"
    elif "Partial" in status:
      cls = "status-partial"
    else:
      cls = "status-plan"
    out.append(f"<tr><td>{c.get('area','')}</td><td><span class='status-pill {cls}'>{status}</span></td><td>{c.get('notes','')}</td></tr>")
  out.append("</tbody></table></div>")
  return "\n".join(out)


def render_log_samples(base_dir: pathlib.Path, max_logs=6):
  logs = sorted(base_dir.glob("*.log"))[:max_logs]
  if not logs:
    return "<p>No logs found.</p>"
  blocks = []
  for p in logs:
    lines = p.read_text().splitlines()[:40]
    joined = "\n".join(lines)
    blocks.append(f"<details><summary>{p.name}</summary><pre>{joined}</pre></details>")
  return "\n".join(blocks)


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--metrics-csv", required=True)
  parser.add_argument("--comparison-json", required=True)
  parser.add_argument("--capability-json", required=True)
  parser.add_argument("--out-html", required=True)
  parser.add_argument("--title", default="NeuraLink Benchmark Report")
  args = parser.parse_args()

  csv_path = pathlib.Path(args.metrics_csv)
  out_html = pathlib.Path(args.out_html)
  base_dir = out_html.parent

  rows = load_csv(csv_path) if csv_path.exists() else []
  comp = read_json(pathlib.Path(args.comparison_json), {})
  cap = read_json(pathlib.Path(args.capability_json), {})

  plot_blocks = []
  for name in SVG_FILES:
    p = base_dir / name
    if p.exists():
      svg = p.read_text()
      plot_blocks.append(f'<section class="plot-card"><h3>{name}</h3>{svg}</section>')

  html = f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>{args.title}</title>
  <style>
    :root {{
      --bg: #f4f7fc;
      --panel: #ffffff;
      --ink: #111827;
      --muted: #6b7280;
      --accent: #1d4ed8;
      --border: #dbe5f1;
      --ok: #16a34a;
      --warn: #d97706;
      --bad: #dc2626;
    }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; font-family: "Segoe UI", Tahoma, sans-serif; background: var(--bg); color: var(--ink); }}
    .wrap {{ width: 100vw; min-height: 100vh; margin: 0; padding: 18px; }}
    .hero {{ background: linear-gradient(140deg, #dbeafe, #f8fafc); border: 1px solid var(--border); border-radius: 14px; padding: 20px 24px; }}
    .hero h1 {{ margin: 0 0 8px; font-size: 30px; }}
    .hero p {{ margin: 4px 0; color: var(--muted); }}
    .section {{ margin-top: 16px; background: var(--panel); border: 1px solid var(--border); border-radius: 14px; padding: 16px; }}
    .stat-grid {{ display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(180px, 1fr)); }}
    .stat {{ border: 1px solid var(--border); border-radius: 10px; padding: 10px; background: #f8fbff; }}
    .stat h3 {{ margin: 0; font-size: 12px; color: var(--muted); text-transform: uppercase; }}
    .stat p {{ margin: 8px 0 0; font-size: 21px; font-weight: 700; color: var(--accent); }}
    .plot-grid {{ display: grid; gap: 12px; grid-template-columns: repeat(auto-fit, minmax(620px, 1fr)); }}
    .plot-card {{ border: 1px solid var(--border); border-radius: 10px; padding: 10px; overflow: hidden; background: #fff; }}
    .plot-card h3 {{ margin: 0 0 8px; font-size: 13px; color: #334155; }}
    .plot-card svg {{ width: 100%; height: auto; display: block; }}
    .table-wrap {{ width: 100%; overflow-x: auto; }}
    .metrics-table {{ width: 100%; min-width: 920px; border-collapse: collapse; font-size: 13px; table-layout: fixed; }}
    .metrics-table th, .metrics-table td {{ border: 1px solid var(--border); padding: 8px 10px; text-align: left; vertical-align: top; }}
    .metrics-table th {{ background: #ecf2ff; }}
    .metrics-table th, .metrics-table td {{ overflow-wrap: anywhere; word-break: break-word; }}
    .muted {{ color: var(--muted); }}
    .compare-grid {{ display: grid; gap: 10px; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); }}
    .compare-card {{ border-radius: 10px; border: 1px solid var(--border); padding: 10px; }}
    .compare-card h3 {{ margin: 0 0 8px; font-size: 14px; }}
    .compare-card p {{ margin: 5px 0; font-size: 13px; }}
    .compare-card.better {{ background: #ecfdf3; border-color: #bbf7d0; }}
    .compare-card.worse {{ background: #fff7ed; border-color: #fed7aa; }}
    .status-pill {{ padding: 3px 8px; border-radius: 999px; font-size: 11px; font-weight: 700; }}
    .status-impl {{ background: #dcfce7; color: #166534; }}
    .status-partial {{ background: #fef9c3; color: #854d0e; }}
    .status-plan {{ background: #fee2e2; color: #991b1b; }}
    pre {{ background: #0f172a; color: #e2e8f0; border-radius: 8px; padding: 10px; overflow-x: auto; }}
    details {{ margin: 8px 0; }}
    @media (max-width: 760px) {{
      .plot-grid {{ grid-template-columns: 1fr; }}
    }}
  </style>
</head>
<body>
  <div class="wrap">
    <section class="hero">
      <h1>{args.title}</h1>
      <p>End-to-end benchmark review with quantitative comparison, visual analytics, and capability matrix.</p>
      <p>Workflow: Verilog simulation produces run metrics; Python orchestrates sweeps, analytics, and visualization rendering.</p>
    </section>

    <section class="section">
      <h2>Aggregate Metrics</h2>
      {render_stats(rows)}
    </section>

    <section class="section">
      <h2>Baseline Comparison (X, Y, Z)</h2>
      {render_comparison(comp)}
    </section>

    <section class="section">
      <h2>Visual Analytics</h2>
      <div class="plot-grid">
        {"".join(plot_blocks) if plot_blocks else "<p>No plots found.</p>"}
      </div>
    </section>

    <section class="section">
      <h2>Numerical Benchmark Table</h2>
      {render_table(rows)}
    </section>

    <section class="section">
      <h2>Capability Matrix</h2>
      {render_capabilities(cap)}
    </section>

    <section class="section">
      <h2>Structured Run Log Samples</h2>
      {render_log_samples(base_dir)}
    </section>
  </div>
</body>
</html>
"""
  out_html.write_text(html)
  print(f"HTML report generated: {out_html}")


if __name__ == "__main__":
  main()
