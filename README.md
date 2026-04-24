# NeuraLink

![Status](https://img.shields.io/badge/status-active%20development-1f6feb)
![RTL](https://img.shields.io/badge/RTL-SystemVerilog-0b7285)
![FPGA](https://img.shields.io/badge/FPGA-Vivado%20TCL%20Flow-6f42c1)
![PD](https://img.shields.io/badge/PD-OpenROAD%20Research-8a5b00)

NeuraLink is a production-oriented accelerator project built as a RISC-V coprocessor platform, with emphasis on memory-aware dataflow, sparse-attention readiness, FPGA validation, and PD-compatible structure.

## Introduction

The project targets real bottlenecks seen in modern transformer-class workloads:

- Memory bandwidth pressure and DRAM round-trip overhead
- Compute underutilization from irregular sequence lengths and sparse patterns
- Pipeline stalls from coupled control/data movement
- KV-cache traffic growth during decoding

## Project Overview

NeuraLink uses separate control and data paths:

- Control path:
  - command queue
  - scheduler and sequencer
  - backpressure/credit logic
  - completion and performance telemetry
- Data path:
  - dual DMA engines
  - bank-aware mapping and scratchpad buffering
  - systolic/vector/op-class compute units

RISC-V coprocessor integration is designed around MMIO descriptor offload first, with custom instruction offload as phase-2.

## Configuration

Main configuration lives in:

- `configs/demo_configs.json`
- `configs/diverse_benchmark_suite.json`
- `configs/operation_experiments.json`
- `configs/capability_matrix.json`
- `configs/baseline_equivalent.json`

Flow-level configuration knobs include:

- `VIVADO_MODE` (`wsl` or `win`)
- `VIVADO_BAT`
- `TOP_MODULE`
- `FPGA_PART`
- `PDK_NAME`

## Features & Applications

- Systolic matrix compute with vector and auxiliary op pipelines
- Decoupled load/compute/store orchestration
- Block-sparse scheduling hooks for attention workloads
- KV paging and cache management hooks
- FlashAttention-style tiling strategy documentation and integration plan
- End-to-end benchmark generation with HTML and visual analytics
- FPGA TCL flow and OpenROAD research flow scaffolds

Representative applications:

- Transformer inference coprocessor research
- Edge AI acceleration experiments
- Architecture/perf tradeoff studies for memory-centric workloads

## Benchmarks

Benchmark outputs include:

- latency, throughput, efficiency, bandwidth utilization, pipeline metrics
- baseline comparison summaries
- charts and consolidated HTML reports

Detailed run steps are separated into dedicated docs.

## Repository Structure

- `rtl/`: compute, control, memory, interconnect, and top-level modules
- `verif/`: unit and integration testbenches plus assertion scaffolding
- `benchmarks/`: parsers, runners, plotting, report generation, UI server
- `scripts/`: setup, simulation, FPGA TCL flow, PD flow
- `docs/`: architecture, execution, FPGA, PD, board guidance
- `configs/`: experiment and capability profiles

## Documentation

- Execution steps: [execution_steps.md](/mnt/d/Repositories/Res_proj/docs/execution_steps.md)
- Full architecture: [full_system_architecture.md](/mnt/d/Repositories/Res_proj/docs/architecture/full_system_architecture.md)
- CPU/offload selection: [cpu_selection_and_offload.md](/mnt/d/Repositories/Res_proj/docs/architecture/cpu_selection_and_offload.md)
- RISC-V coprocessor integration: [riscv_coprocessor_integration.md](/mnt/d/Repositories/Res_proj/docs/architecture/riscv_coprocessor_integration.md)
- Transformer dataflow/sparsity: [transformer_dataflow_and_sparsity.md](/mnt/d/Repositories/Res_proj/docs/architecture/transformer_dataflow_and_sparsity.md)
- FPGA flow: [fpga_vivado_flow.md](/mnt/d/Repositories/Res_proj/docs/flows/fpga_vivado_flow.md)
- PD flow: [pd_openroad_flow.md](/mnt/d/Repositories/Res_proj/docs/flows/pd_openroad_flow.md)
- Board recommendations: [fpga_board_recommendations.md](/mnt/d/Repositories/Res_proj/docs/flows/fpga_board_recommendations.md)
- Version-control workflow: [version_control_guidelines.md](/mnt/d/Repositories/Res_proj/docs/workflows/version_control_guidelines.md)
