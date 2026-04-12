#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/common/logging.sh"
BUILD_DIR="$ROOT_DIR/build"
mkdir -p "$BUILD_DIR"

log_section "Build Simulation Binary"
log_info "Compiling accelerator bench testbench"
iverilog -g2012 \
  -o "$BUILD_DIR/accelerator_bench.out" \
  "$ROOT_DIR/rtl/core/mac_pe.sv" \
  "$ROOT_DIR/rtl/core/pe_array.sv" \
  "$ROOT_DIR/verif/tb/accelerator_bench_tb.sv"

log_success "Built: $BUILD_DIR/accelerator_bench.out"
