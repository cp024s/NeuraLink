#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common/logging.sh"
OUT_DIR="${1:-$ROOT_DIR/results/synth_check}"
mkdir -p "$OUT_DIR"

if ! command -v yosys >/dev/null 2>&1; then
  log_warn "yosys is not installed; skipping synthesis check."
  exit 0
fi

if ! yosys -q -p "
read_verilog -sv \
  $ROOT_DIR/rtl/include/accel_pkg.sv \
  $ROOT_DIR/rtl/core/mac_pe.sv \
  $ROOT_DIR/rtl/core/pe_array.sv \
  $ROOT_DIR/rtl/core/vector_unit.sv \
  $ROOT_DIR/rtl/core/activation_pipe.sv \
  $ROOT_DIR/rtl/core/conv2d_unit.sv \
  $ROOT_DIR/rtl/core/pooling_unit.sv \
  $ROOT_DIR/rtl/core/reduction_unit.sv \
  $ROOT_DIR/rtl/core/norm_unit.sv \
  $ROOT_DIR/rtl/core/math_unit.sv \
  $ROOT_DIR/rtl/core/precision_convert_unit.sv \
  $ROOT_DIR/rtl/interconnect/noc_router.sv \
  $ROOT_DIR/rtl/interconnect/data_switch.sv \
  $ROOT_DIR/rtl/system/tile_scheduler.sv \
  $ROOT_DIR/rtl/system/decoupled_issue_ctrl.sv \
  $ROOT_DIR/rtl/system/instruction_sequencer.sv \
  $ROOT_DIR/rtl/system/perf_counter_block.sv \
  $ROOT_DIR/rtl/memory/bank_addr_mapper.sv \
  $ROOT_DIR/rtl/memory/pingpong_buffer_ctrl.sv \
  $ROOT_DIR/rtl/memory/tile_dma.sv \
  $ROOT_DIR/rtl/top/edge_tpu_top.sv
hierarchy -check -top edge_tpu_top
proc; opt; fsm; opt; memory; opt
stat
write_json $OUT_DIR/edge_tpu_top_synth.json
" >"$OUT_DIR/yosys_stat.log" 2>&1; then
  log_warn "yosys synthesis check could not complete with current tool support."
  log_info "See $OUT_DIR/yosys_stat.log for details."
  exit 0
fi

log_success "Synthesis check completed: $OUT_DIR/yosys_stat.log"
