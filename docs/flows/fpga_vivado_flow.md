# FPGA Vivado Flow (TCL/CLI)

This project uses Vivado in `-mode tcl` only. GUI and batch project clicks are intentionally avoided.

## Mode Switching

Set one variable and keep the script unchanged:

- `VIVADO_MODE=wsl` for WSL2 invoking Windows Vivado through `cmd.exe`
- `VIVADO_MODE=win` for native Windows shell

Script:

- `scripts/fpga/vivado_flow.sh`
- TCL source: `scripts/fpga/vivado_project.tcl`

## Example Invocations

- WSL2:
  - `VIVADO_MODE=wsl VIVADO_BAT='C:\Xilinx\2025.1\Vivado\bin\vivado.bat' bash scripts/fpga/vivado_flow.sh`
- Windows:
  - `VIVADO_MODE=win VIVADO_BAT='C:\Xilinx\2025.1\Vivado\bin\vivado.bat' bash scripts/fpga/vivado_flow.sh`

## Key Parameters

- `TOP_MODULE` default: `edge_tpu_top`
- `FPGA_PART` default: `xc7a200tfbg484-1`
- `BUILD_DIR` default: `build/vivado`

## Outputs

- `utilization.rpt`
- `timing_summary.rpt`
- `post_route.dcp`
- `<top>.edf`

## Notes

- Current top is suitable for synthesis and integration checks.
- Board-specific constraints/XDC should be added per platform in a board folder before lab deployment.
