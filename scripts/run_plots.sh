#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
METRICS_CSV="${1:-$ROOT_DIR/results/latest/metrics.csv}"
OUT_DIR="${2:-$(dirname "$METRICS_CSV")}"

python3 "$ROOT_DIR/benchmarks/plot_metrics.py" \
  --input "$METRICS_CSV" \
  --out-dir "$OUT_DIR"
