# Execution Steps

This file contains runnable flow entry points.  
The `README.md` stays overview-centric by design.

## 1. Environment Bootstrap

- Install dependencies: `bash scripts/setup/install_open_source_tools.sh`
- Python packages: `pip3 install -r requirements.txt`
- Load flow defaults: `source configs/toolchain_modes.env`

## 2. RTL Simulation and Verification

- Build simulation binary: `make build`
- Unit-level operation tests: `make op_tb`
- Decoupled controller tests: `make issue_tb`
- RISC-V bridge tests: `make bridge_tb`
- Top-level integration test: `make system_tb`

## 3. Benchmark and Reporting

- Standard sweep: `make run`
- Dynamic sweep: `make dynamic_run ROWS_LIST=4,8,16 COLS_LIST=4,8,16 K_LIST=32,64`
- Input suite: `make input_suite`
- Interactive web server: `make ui`

## 4. FPGA Flow (Vivado TCL/CLI only)

- WSL mode (recommended from WSL2):  
  `VIVADO_MODE=wsl VIVADO_BAT='C:\Xilinx\2025.1\Vivado\bin\vivado.bat' bash scripts/fpga/vivado_flow.sh`
- Native Windows shell mode:  
  `VIVADO_MODE=win VIVADO_BAT='C:\Xilinx\2025.1\Vivado\bin\vivado.bat' bash scripts/fpga/vivado_flow.sh`

Use `TOP_MODULE` and `FPGA_PART` environment variables to retarget.

## 5. Physical Design Flow (OpenROAD research mode)

- Run PD flow: `bash scripts/pd/openroad_flow.sh`
- Optional full-PDK run by exporting:
  - `TECH_LEF`
  - `STDCELL_LEF`
  - `STDCELL_LIB`
  - `PDK_NAME` (for tracking only)

Without those variables, the flow executes netlist checks and timing placeholders.
