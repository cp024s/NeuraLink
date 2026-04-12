#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common/logging.sh"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="$ROOT_DIR/results/demo_$STAMP"

log_section "NeuraLink Demo Flow"
log_info "Output directory: $OUT_DIR"
"$ROOT_DIR/scripts/build_sim.sh"
"$ROOT_DIR/scripts/run_sweep.sh" "$ROOT_DIR/configs/demo_configs.json" "$OUT_DIR"
log_info "Generating markdown summary"
python3 "$ROOT_DIR/benchmarks/metrics_report.py" \
  --input "$OUT_DIR/metrics.csv" \
  --output "$OUT_DIR/summary.md"
log_info "Generating plots"
python3 "$ROOT_DIR/benchmarks/plot_metrics.py" \
  --input "$OUT_DIR/metrics.csv" \
  --out-dir "$OUT_DIR"
log_info "Generating baseline comparison"
python3 "$ROOT_DIR/benchmarks/baseline_compare.py" \
  --metrics-csv "$OUT_DIR/metrics.csv" \
  --baseline-json "$ROOT_DIR/configs/baseline_equivalent.json" \
  --out-json "$OUT_DIR/baseline_comparison.json"
log_info "Generating HTML report"
python3 "$ROOT_DIR/benchmarks/html_report.py" \
  --metrics-csv "$OUT_DIR/metrics.csv" \
  --comparison-json "$OUT_DIR/baseline_comparison.json" \
  --capability-json "$ROOT_DIR/configs/capability_matrix.json" \
  --out-html "$OUT_DIR/benchmark_report.html" \
  --title "NeuraLink Benchmark Report"

log_success "Demo artifacts: $OUT_DIR"
