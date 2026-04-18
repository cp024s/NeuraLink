# Research Adaptation Notes

This document tracks research/industry ideas and how they are adapted pragmatically in NeuraLink.

## Intel Gaudi-Inspired Themes (Adapted)

- Explicit overlap between communication and compute
  - Adaptation: decoupled load/compute/store control and ping-pong buffering
- High-throughput tensor-centric pipelines
  - Adaptation: systolic + vector + op-class decomposition
- Scalable interconnect visibility
  - Adaptation: NoC flit counters and routing-level instrumentation

## NPU Literature Themes (Adapted)

- Dataflow specialization to reduce memory movement
  - Adaptation: descriptor-selectable dataflow modes and tiled execution
- Structured sparsity for hardware-friendly skipping
  - Adaptation: block-mask scheduler hooks and deterministic sparse block order
- KV cache pressure management
  - Adaptation: paged KV cache manager and prefix reuse strategy hooks

## Practical Integration Policy

- Use reference repositories for conceptual architecture understanding only.
- No direct code copy from external projects.
- Each borrowed concept must be transformed into:
  - explicit module responsibility
  - measurable metric target
  - verifiable test strategy
