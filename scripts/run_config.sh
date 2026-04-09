#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 6 ]]; then
  echo "Usage: $0 <rows> <cols> <k> <warmup> <maxbw> <output_log>"
  exit 1
fi

ROWS="$1"
COLS="$2"
KDIM="$3"
WARMUP="$4"
MAXBW="$5"
OUT_LOG="$6"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT_DIR/build/accelerator_bench.out"

if [[ ! -f "$BIN" ]]; then
  "$ROOT_DIR/scripts/build_sim.sh"
fi

mkdir -p "$(dirname "$OUT_LOG")"
vvp "$BIN" +ROWS="$ROWS" +COLS="$COLS" +K="$KDIM" +WARMUP="$WARMUP" +MAXBW="$MAXBW" > "$OUT_LOG"
echo "Run complete: $OUT_LOG"
