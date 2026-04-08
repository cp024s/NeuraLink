# Research-Grade TPU / Edge AI Accelerator Blueprint

## 1) Design Target

Build a scalable accelerator that is **memory-first**:
- Maximize on-chip reuse and tile residency.
- Keep processing elements (PEs) busy with predictable schedules.
- Support dense and sparse kernels, plus attention-style workloads.
- Keep RTL modular so dataflow, memory, and interconnect can evolve independently.

## 2) Bottleneck-to-Architecture Mapping

### Memory bandwidth + data movement energy
- Use a 3-level hierarchy: `DRAM -> global SRAM -> distributed scratchpads`.
- Add a tile-aware DMA engine so only tile boundaries touch DRAM.
- Keep activations stationary in scratchpad where possible; stream weights/partials by dataflow mode.

### PE underutilization
- Add credit-based work queues and tile descriptors to reduce PE bubbles.
- Use small local FIFOs and backpressure (`valid/ready`) at each PE edge.
- Enable mode-level specialization: GEMM mode, depthwise mode, sparse mode.

### Interconnect scaling
- Replace shared buses with packetized on-chip network (NoC) or hierarchical crossbars.
- Partition compute into clusters (e.g. `8x8` PE cluster) with local reduction.
- Promote locality first: route to nearest cluster containing needed tile.

### Sparse inefficiency
- Prefer block/structured sparsity (`N:M`, block CSR/CSC) to avoid irregular control.
- Attach metadata lanes to data packets so decompression is streaming, not random-access.
- Add zero-skip in PE pipeline with deterministic bookkeeping.

### Attention complexity + KV cache growth
- Tile attention by sequence blocks (`QK^T` and `softmax*V` in chunks).
- Keep partial max/sum for online softmax in on-chip SRAM.
- Add configurable KV cache compression (quantization + block pruning).

## 3) Recommended Macro-Architecture

1. **Host + Runtime Layer**
   - Command queue, model graph executor, tile scheduler.
2. **Global Memory Subsystem**
   - DRAM controller + tile DMA + prefetch policy.
3. **Clustered Compute Fabric**
   - Multiple PE clusters, each with local scratchpad and reduction tree.
4. **Interconnect**
   - Lightweight packet NoC for activation/weight/partial exchanges.
5. **Special Function Units (optional path)**
   - LayerNorm, softmax helper, activation units.

## 4) Dataflow Strategy (Runtime-Selectable)

- **Weight-stationary** for convolution-like reuse.
- **Output-stationary** for GEMM/attention matmul accumulation.
- **Row/column stationary variants** for memory-constrained edge targets.

Expose dataflow as control CSR fields, not hardcoded compile-time behavior.

## 5) RTL Modularity Contract

Keep clean boundaries:
- `rtl/include/accel_pkg.sv`: types, params, opcodes, tile descriptor structs.
- `rtl/core/mac_pe.sv`: single PE pipeline + zero-skip.
- `rtl/core/pe_array.sv`: scalable MxN grid and edge handshakes.
- `rtl/memory/*`: scratchpad banks + tile DMA.
- `rtl/top/edge_tpu_top.sv`: integration shell for bring-up.

All data channels should use `valid/ready` semantics to simplify composition and formal checks.

## 6) Verification Strategy

### Unit level
- PE arithmetic correctness, saturation/truncation, reset, clear behavior.
- Scratchpad read/write hazards and bank conflicts.
- DMA descriptor sequencing and boundary checks.

### Subsystem level
- PE array progress tests under randomized backpressure.
- Dataflow mode switching correctness across tiles.
- Sparse metadata decode + skip behavior checks.

### System level
- End-to-end kernel tests: GEMM, conv, attention tile path.
- Scoreboard against software reference model (bit-accurate where feasible).
- Performance counters checked for utilization and DRAM transaction bounds.

### Assertions and coverage
- Assertions: no handshake loss, no out-of-range memory accesses, no deadlock.
- Functional coverage: dataflow modes, tile sizes, sparsity patterns, burst shapes.

## 7) Performance Counters (Must-Have)

Expose counters through CSRs:
- `pe_active_cycles`, `pe_idle_cycles`, `zero_skip_events`
- `dram_read_bytes`, `dram_write_bytes`, `dma_stall_cycles`
- `noc_flit_count`, `noc_backpressure_cycles`
- `attention_tile_reloads`, `kv_cache_hits/misses`

These are essential for bottleneck closure, not optional instrumentation.

## 8) Milestone Plan

1. **M0 Bring-up**
   - Single-cluster dense GEMM path with deterministic tests.
2. **M1 Memory closure**
   - Tile DMA + scratchpad residency; validate DRAM traffic reductions.
3. **M2 Sparsity path**
   - Structured sparsity metadata + zero-skip PE mode.
4. **M3 Attention path**
   - Tiled attention matmul + online softmax helper.
5. **M4 Scale-out**
   - Multi-cluster NoC, throughput/perf counter validation.

## 9) Immediate Next Work in RTL

- Implement descriptor-driven tile scheduler.
- Add formal-ready channel wrappers for every data path.
- Add reference-model co-sim hooks for subsystem regressions.
- Freeze interface versioning before expanding features.
