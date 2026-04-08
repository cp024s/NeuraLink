# Reference Integration Plan

This project uses external repositories as targeted design inputs rather than copy-paste dependencies.

## Mapped references

- `bsc-loca/sauria`: dataflow and memory hierarchy organization reference.
- `BoChen-Ye/Tiny_LeViT_Hardware_Accelerator`: attention-support hardware decomposition ideas.
- `abdelazeem201/Systolic-array-implementation-in-RTL-for-TPU`: RTL PE-array baseline patterns.
- `lllibano/SystolicArray`: quick experimentation and functional prototyping patterns.
- `nvdla/hw` (optional heavy pull): industrial-style subsystem decomposition and control concepts.

## Integration approach

1. Identify reusable **interfaces and architectural patterns**, not wholesale RTL import.
2. Create local equivalent modules with project naming and verification contracts.
3. Track each adopted idea in a design log entry (`source`, `adaptation`, `validation test`).
4. Validate each adaptation through local regression scripts and metrics.

## Why this approach

- Keeps the codebase cohesive and presentation-ready.
- Avoids license and maintenance risk of tightly coupled external RTL.
- Enables clear stakeholder explanation of design provenance and improvements.
