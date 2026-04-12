#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common/logging.sh"
CFG_FILE="${1:-$ROOT_DIR/configs/input_case.json}"
OUT_DIR="${2:-$ROOT_DIR/results/input_case_latest}"

log_section "Input Case"
log_info "Config=$CFG_FILE out_dir=$OUT_DIR"
"$ROOT_DIR/scripts/build_sim.sh"
python3 "$ROOT_DIR/benchmarks/process_input_case.py" \
  --config "$CFG_FILE" \
  --out-dir "$OUT_DIR" \
  --rows "${ROWS:-0}" \
  --cols "${COLS:-0}" \
  --k "${KDIM:-0}" \
  --seed "${SEED:-11}"
log_success "Input case complete: $OUT_DIR"
