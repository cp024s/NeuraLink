#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build/pd}"
PDK_NAME="${PDK_NAME:-openrpd28}"
TOP_MODULE="${TOP_MODULE:-edge_tpu_top}"
RTL_LIST="${RTL_LIST:-$ROOT_DIR/scripts/pd/rtl_files.txt}"
OPENROAD_TCL="${OPENROAD_TCL:-$ROOT_DIR/scripts/pd/openroad_flow.tcl}"

mkdir -p "$BUILD_DIR"

if ! command -v yosys >/dev/null 2>&1; then
  echo "[pd] yosys is required but not found." >&2
  exit 1
fi
if ! command -v openroad >/dev/null 2>&1; then
  echo "[pd] openroad is required but not found." >&2
  exit 1
fi

if [[ ! -f "$RTL_LIST" ]]; then
  echo "[pd] RTL list not found: $RTL_LIST" >&2
  exit 1
fi

YOSYS_SCRIPT_GEN="$BUILD_DIR/synth_openroad.ys"
{
  echo "read_verilog -sv $ROOT_DIR/rtl/include/accel_pkg.sv"
  while IFS= read -r rtl; do
    [[ -z "$rtl" || "$rtl" =~ ^# ]] && continue
    echo "read_verilog -sv $ROOT_DIR/$rtl"
  done < "$RTL_LIST"
  echo "hierarchy -check -top $TOP_MODULE"
  echo "proc; opt; fsm; opt; memory; opt"
  echo "techmap; opt"
  echo "abc -fast"
  echo "clean"
  echo "write_verilog $BUILD_DIR/${TOP_MODULE}_synth.v"
  echo "stat > $BUILD_DIR/yosys_stat.rpt"
} > "$YOSYS_SCRIPT_GEN"

echo "[pd] Running synthesis for $TOP_MODULE"
yosys -s "$YOSYS_SCRIPT_GEN"

echo "[pd] Running OpenROAD implementation with PDK=$PDK_NAME"
export ROOT_DIR BUILD_DIR TOP_MODULE PDK_NAME
openroad -exit "$OPENROAD_TCL"

echo "[pd] PD flow complete. Check $BUILD_DIR for netlist/reports/GDS placeholders."
