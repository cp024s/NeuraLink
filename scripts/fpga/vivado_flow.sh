#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# Mode can be switched manually in one place:
#   VIVADO_MODE=wsl  -> invoke Windows Vivado from WSL through cmd.exe
#   VIVADO_MODE=win  -> invoke Vivado directly from Windows shell
VIVADO_MODE="${VIVADO_MODE:-wsl}"
VIVADO_BAT="${VIVADO_BAT:-C:\\Xilinx\\2025.1\\Vivado\\bin\\vivado.bat}"
FPGA_PART="${FPGA_PART:-xc7a200tfbg484-1}"
TOP_MODULE="${TOP_MODULE:-edge_tpu_top}"
BUILD_DIR="${BUILD_DIR:-$ROOT_DIR/build/vivado}"

mkdir -p "$BUILD_DIR"

TCL_SCRIPT="$ROOT_DIR/scripts/fpga/vivado_project.tcl"
REPORT_DIR="$BUILD_DIR/reports"
mkdir -p "$REPORT_DIR"

run_vivado_wsl() {
  local tcl_win
  local build_win
  local root_win
  tcl_win="$(wslpath -w "$TCL_SCRIPT")"
  build_win="$(wslpath -w "$BUILD_DIR")"
  root_win="$(wslpath -w "$ROOT_DIR")"
  cmd.exe /C "\"$VIVADO_BAT\" -mode tcl -source \"$tcl_win\" -tclargs \"$root_win\" \"$build_win\" \"$TOP_MODULE\" \"$FPGA_PART\""
}

run_vivado_win() {
  "$VIVADO_BAT" -mode tcl -source "$TCL_SCRIPT" -tclargs "$ROOT_DIR" "$BUILD_DIR" "$TOP_MODULE" "$FPGA_PART"
}

echo "[fpga] Mode=$VIVADO_MODE Top=$TOP_MODULE Part=$FPGA_PART"
if [[ "$VIVADO_MODE" == "wsl" ]]; then
  run_vivado_wsl
elif [[ "$VIVADO_MODE" == "win" ]]; then
  run_vivado_win
else
  echo "[fpga] Unsupported VIVADO_MODE=$VIVADO_MODE (use wsl|win)" >&2
  exit 1
fi

echo "[fpga] Vivado TCL flow complete. Artifacts in $BUILD_DIR"
