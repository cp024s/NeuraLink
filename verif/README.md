# Verification Notes

## Current assets

- `tb/pe_array_smoke_tb.sv`: minimal compile/run sanity test for the PE array.
- `sva/pe_array_sva.sv`: starter assertion scaffold for validity-signal hygiene.

## Suggested immediate upgrades

- Add a software scoreboard for deterministic GEMM tiles.
- Add randomized valid/ready backpressure cases.
- Add assertions for reset/clear convergence and deadlock freedom.
- Add coverage for dataflow modes and sparse-enable transitions.
