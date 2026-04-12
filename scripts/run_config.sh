#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 6 ]]; then
  echo "Usage: $0 <rows> <cols> <k> <warmup> <maxbw> <output_log> [opclass]"
  exit 1
fi

ROWS="$1"
COLS="$2"
KDIM="$3"
WARMUP="$4"
MAXBW="$5"
OUT_LOG="$6"
OPCLASS="${7:-0}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common/logging.sh"
BIN="$ROOT_DIR/build/accelerator_bench.out"

if [[ ! -f "$BIN" ]]; then
  log_warn "Simulation binary not found. Triggering build."
  "$ROOT_DIR/scripts/build_sim.sh"
fi

mkdir -p "$(dirname "$OUT_LOG")"
log_section "Run Config"
log_info "rows=$ROWS cols=$COLS k=$KDIM warmup=$WARMUP maxbw=$MAXBW opclass=$OPCLASS"
vvp "$BIN" +ROWS="$ROWS" +COLS="$COLS" +K="$KDIM" +WARMUP="$WARMUP" +MAXBW="$MAXBW" +OPCLASS="$OPCLASS" > "$OUT_LOG"
if rg -q "^METRIC " "$OUT_LOG"; then
  log_success "Run complete: $OUT_LOG"
  if [[ "${DEBUG:-0}" == "1" ]]; then
    log_debug "Metrics summary:"
    rg "^METRIC " "$OUT_LOG" || true
  fi
else
  log_error "Run finished but no METRIC lines were found in $OUT_LOG"
  exit 1
fi
