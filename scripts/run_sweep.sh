#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${1:-$ROOT_DIR/configs/demo_configs.json}"
OUT_DIR="${2:-$ROOT_DIR/results/latest}"

python3 "$ROOT_DIR/benchmarks/benchmark_runner.py" \
  --config "$CONFIG_FILE" \
  --out-dir "$OUT_DIR"
