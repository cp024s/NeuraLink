#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG_FILE="${1:-$ROOT_DIR/configs/input_case.json}"
OUT_DIR="${2:-$ROOT_DIR/results/input_case_latest}"

"$ROOT_DIR/scripts/build_sim.sh"
python3 "$ROOT_DIR/benchmarks/process_input_case.py" \
  --config "$CFG_FILE" \
  --out-dir "$OUT_DIR"
