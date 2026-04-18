# Transformer Dataflow and Sparsity Strategy

This document maps the requested memory/dataflow challenges into implementable algorithm + RTL hooks.

## Control Path vs Data Path

NeuraLink uses explicit separation:

- Control path:
  - command queue
  - scheduler/sequencer
  - backpressure/credit logic
  - completion/interrupt/perf accounting
- Data path:
  - DMA + scratchpad
  - systolic/vector/op compute blocks
  - data switch and reduction paths

## 1. Backpressure Handling Algorithm

Credit-based stall control:

1. Each queue tracks `credit_used` vs `max_credit`.
2. `stall` asserts when outstanding requests reach credit limit.
3. Upstream issue logic pauses enqueue while downstream drains.
4. Credits are released strictly on dequeue/ack.

RTL hook:

- `rtl/system/backpressure_controller.sv`

## 2. Bandwidth and Locality Algorithms

## FlashAttention-Style Block Tiling

- Partition Q/K/V into SRAM-sized tiles.
- Compute softmax in streaming/incremental form inside tile windows.
- Store only final O blocks; avoid writing full attention matrix to DRAM.

## SRAM Reuse

- Keep K/V tile resident while sweeping multiple Q blocks.
- Evict on tile completion or pressure event.

## Double Buffering

- Buffer A: compute current tile.
- Buffer B: prefetch next tile.
- Swap buffers every tile epoch.

## KV Cache Optimization

- Use paged KV tables rather than monolithic linear cache.
- Reuse prefixes when prompt overlap exists.
- Optional KV sharing policy across heads where model constraints permit.

RTL hook:

- `rtl/memory/kv_cache_pager.sv`

## 3. Sparse Attention Mapping

## Block Sparse + Structured Masking

- Represent active blocks with mask bitmaps.
- Skip zero/invalid blocks entirely in scheduler.
- Maintain deterministic block order for timing predictability.

RTL hook:

- `rtl/system/block_sparse_attention_scheduler.sv`

## 4. Utilization and Stall Mitigation

Addressed issues:

- Irregular sequence lengths:
  - dynamic block masks + variable tile descriptors
- Pipeline stalls:
  - decoupled load/compute/store control
- Memory stalls:
  - bank-aware addressing + ping-pong buffering
- Poor scheduling:
  - descriptor-driven queueing with explicit op-class routes

## 5. Planned Extensions

- Operator fusion pass in scheduler (QK matmul + softmax + V projection microflow)
- Segmented long-context attention to cap scratchpad footprint
- Runtime policy knob for sparse density threshold switching
