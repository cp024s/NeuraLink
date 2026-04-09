#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAMP="$(date +%Y%m%d_%H%M%S)"
OUT_DIR="$ROOT_DIR/results/demo_$STAMP"

"$ROOT_DIR/scripts/build_sim.sh"
"$ROOT_DIR/scripts/run_sweep.sh" "$ROOT_DIR/configs/demo_configs.json" "$OUT_DIR"
python3 "$ROOT_DIR/benchmarks/metrics_report.py" \
  --input "$OUT_DIR/metrics.csv" \
  --output "$OUT_DIR/summary.md"
python3 "$ROOT_DIR/benchmarks/plot_metrics.py" \
  --input "$OUT_DIR/metrics.csv" \
  --out-dir "$OUT_DIR"

echo "Demo artifacts: $OUT_DIR"
