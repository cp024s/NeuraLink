#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common/logging.sh"
OUT_BASE="${1:-$ROOT_DIR/results/input_suite_latest}"
mkdir -p "$OUT_BASE"

cases=(
  "$ROOT_DIR/configs/input_case_small.json"
  "$ROOT_DIR/configs/input_case_medium.json"
  "$ROOT_DIR/configs/input_case_generated.json"
)

for cfg in "${cases[@]}"; do
  name="$(basename "$cfg" .json)"
  out_dir="$OUT_BASE/$name"
  log_info "Running case: $name"
  "$ROOT_DIR/scripts/run_input_case.sh" "$cfg" "$out_dir"
done

log_success "Input suite complete: $OUT_BASE"
