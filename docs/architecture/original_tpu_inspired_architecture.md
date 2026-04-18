# Original TPU-Inspired Accelerator Architecture (Educational)

## Intent and scope

This document defines an **original**, educational accelerator architecture inspired by high-level principles from publicly available TPU system descriptions.

It is not a TPU reimplementation and does not copy code, structure, or implementation details from external repositories or vendor hardware.

## Non-goals and provenance constraints

- No direct reuse of RTL, module hierarchy, or control microarchitecture from any reference repository.
- No copy-paste of interfaces, scripts, or verification environments from external sources.
- External repositories are used only as conceptual reading material to inform tradeoff discussions.

## Top-level architecture

The accelerator is partitioned into independent subsystems with explicit contracts:

1. Instruction Sequencer and Control Unit
- Fetches macro-instructions from host command queue.
- Expands instructions into tile descriptors and schedules execution epochs.
- Tracks hazards between memory movement and compute issue.

2. Matrix Compute Cluster (Primary Engine)
- Contains multiple Matrix Multiplication Units (MMUs) built around a systolic array fabric.
- Supports dense GEMM and structured sparse GEMM modes.
- Uses output-stationary accumulation for stable writeback behavior.

3. Vector Processing Unit (VPU)
- Executes non-matmul kernels: elementwise ops, normalization assists, reduction tails.
- Handles activation-side math and post-processing without stalling MMUs.

4. Activation Pipeline
- Dedicated streaming pipeline for activation functions and optional quant/dequant steps.
- Operates on vector lanes and receives batched outputs from MMU/VPU paths.

5. Memory Subsystem (DDR-preferred)
- DDR controller front-end with burst-aware DMA request shaping.
- On-chip global buffer plus distributed scratchpads for tile residency.
- Optional cache-like metadata layer for recurrent tensor regions.

6. DMA Engine
- Descriptor-driven mover for host<->DDR and DDR<->on-chip transfers.
- Supports prefetch, double-buffering, and prioritized writeback channels.

7. Interconnect and Data Switch
- Packetized NoC-style fabric for cluster-to-memory and cluster-to-cluster transfers.
- Arbitration policy favors forward progress and fairness under congestion.
- Data switch routes streams based on descriptor tags and destination class.

8. SerDes Boundary
- Serializer/Deserializer blocks for external high-speed links or chiplet-style expansion.
- Can be bypassed in single-die educational simulation mode.

## Core compute fabric

### Systolic array design
- 2D array of MAC processing elements with deterministic wavefront timing.
- Local forwarding paths reduce repeated global memory reads.
- Structured sparsity gating in PE datapath mitigates wasted MAC cycles.

### MMU behavior
- MMU accepts tile descriptors: `{M, N, K, precision_mode, sparsity_mode}`.
- Performs staged load/compute/store pipeline with overlap.
- Emits performance events for utilization and stall diagnosis.

## Memory and data movement strategy

### DDR-centric design choice
- Prefer DDR workflow for broad FPGA feasibility and lower integration complexity.
- Compensate lower bandwidth vs HBM with:
  - larger tile reuse windows,
  - multi-bank scratchpad access,
  - aggressive prefetch overlap,
  - compressed sparse payload paths.

### On-chip buffering
- Global buffer holds incoming tiles and intermediate blocks.
- Scratchpads are banked per compute cluster to reduce contention.
- Ping-pong buffering supports compute/transfer concurrency.

### Cache hierarchy (applicable mode)
- Not a CPU-style transparent cache by default.
- Optional software-managed region cache for reusable model weights or KV blocks.

## Bottleneck mitigation plan

1. Memory bandwidth limitations
- Tile-first execution and DMA burst coalescing.
- Read prioritization for compute-critical streams.

2. Data movement overhead
- Keep partial sums on-chip until final writeback.
- Interconnect multicast for shared weight tiles.

3. Compute underutilization
- Credit-based work queues per cluster.
- Dynamic issue throttling to match data readiness.

4. Interconnect pressure
- Virtual channels for memory, control, and result traffic classes.
- Backpressure propagation with deadlock-safe routing rules.

5. Attention-like workloads
- Blocked Q/K/V flow with on-chip partial reduce state.
- VPU-assisted softmax and normalization tails.

## Instruction model (educational ISA sketch)

- `LOAD_TILE`
- `MMU_MATMUL`
- `VPU_OP`
- `ACT_PIPE`
- `STORE_TILE`
- `BARRIER`
- `EVENT_READ`

The instruction sequencer composes these into repeatable kernel templates.

## Verification-oriented observability

Mandatory counters/events:
- PE active vs idle cycles
- DMA active/stall cycles
- NoC flit counts and backpressure cycles
- Scratchpad bank conflict events
- Activation pipeline occupancy

This instrumentation is required to evaluate architecture decisions, not optional debug.

## Educational positioning

- Purpose: learning, experimentation, and architectural analysis.
- Not intended for production deployment or vendor equivalence claims.
- Suitable for stakeholder demos focused on design rationale, bottleneck closure, and measured trends.
