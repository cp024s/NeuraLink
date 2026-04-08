# RTL Structure

This directory is organized to let us scale from a small prototype to a research-grade accelerator without breaking interfaces.

## Layout

- `include/accel_pkg.sv`: global parameters, enums, descriptor structs.
- `core/mac_pe.sv`: configurable multiply-accumulate PE with sparse skip.
- `core/pe_array.sv`: scalable 2D PE mesh with wavefront forwarding.
- `memory/scratchpad_bank.sv`: simple scratchpad bank primitive.
- `memory/tile_dma.sv`: descriptor-driven tile transfer issue logic.
- `system/tile_scheduler.sv`: queue-based tile descriptor scheduler.
- `system/perf_counter_block.sv`: always-on performance instrumentation block.
- `interconnect/noc_router.sv`: lightweight NoC router primitive.
- `top/edge_tpu_top.sv`: integration shell for full-system hookup.

## Design notes

- Keep all external interfaces explicit and handshake-based as complexity grows.
- Add dedicated counter blocks early so performance debugging is data-driven.
- Keep sparse and dense paths sharing the same timing contracts.
