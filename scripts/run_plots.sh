#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common/logging.sh"
METRICS_CSV="${1:-$ROOT_DIR/results/latest/metrics.csv}"
OUT_DIR="${2:-$(dirname "$METRICS_CSV")}"

log_section "Plot Metrics"
log_info "Input=$METRICS_CSV out_dir=$OUT_DIR"
python3 "$ROOT_DIR/benchmarks/plot_metrics.py" \
  --input "$METRICS_CSV" \
  --out-dir "$OUT_DIR"
log_success "Plots generated in: $OUT_DIR"
