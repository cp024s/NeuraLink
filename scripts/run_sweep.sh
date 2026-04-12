#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common/logging.sh"
CONFIG_FILE="${1:-$ROOT_DIR/configs/demo_configs.json}"
OUT_DIR="${2:-$ROOT_DIR/results/latest}"

log_section "Benchmark Sweep"
if [[ "${DYNAMIC_SWEEP:-0}" == "1" ]]; then
  log_info "Mode=dynamic out_dir=$OUT_DIR seed=${SEED:-7}"
  python3 "$ROOT_DIR/benchmarks/benchmark_runner.py" \
    --rows-list "${ROWS_LIST:-4,8,12}" \
    --cols-list "${COLS_LIST:-4,8,12}" \
    --k-list "${K_LIST:-16,32,64}" \
    --warmup "${WARMUP:-4}" \
    --maxbw "${MAXBW:-64}" \
    --random-samples "${RANDOM_SAMPLES:-6}" \
    --seed "${SEED:-7}" \
    --meta "dynamic_sweep" \
    --out-dir "$OUT_DIR"
else
  log_info "Mode=config config=$CONFIG_FILE out_dir=$OUT_DIR"
  python3 "$ROOT_DIR/benchmarks/benchmark_runner.py" \
    --config "$CONFIG_FILE" \
    --meta "config_sweep" \
    --out-dir "$OUT_DIR"
fi

log_success "Sweep completed: $OUT_DIR"
