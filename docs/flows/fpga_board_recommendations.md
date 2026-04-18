# FPGA Board Recommendations

These boards are practical for validating a RISC-V + accelerator coprocessor flow with meaningful DSP/LUT pressure.

## 1. Cost-Effective Bring-Up

### Digilent Arty A7-100T
- Good for: control-path validation, MMIO bring-up, reduced-scale datapath
- Why: strong community support, easy Vivado onboarding, low cost
- Tradeoff: limited DSP/BRAM headroom for large attention kernels

### Digilent Nexys Video (Artix-7 200T)
- Good for: medium-scale compute validation and richer IO experiments
- Why: substantially higher fabric capacity than entry boards
- Tradeoff: still not ideal for full-sized transformer-like experiments

## 2. Balanced Performance Option

### PYNQ-Z2 / Zynq-7000 class boards
- Good for: CPU + accelerator integration with software-driven control
- Why: ARM processing system simplifies firmware/runtime loops
- Tradeoff: PL capacity is moderate for large sparse-attention experiments

## 3. Recommended Primary Validation Target

### Kria KV260 or ZCU104 (UltraScale+)
- Good for: larger DSP footprints, better memory bandwidth experiments, realistic coprocessor workload tests
- Why: enough fabric and memory subsystem performance for block-tiling and dataflow stress
- Tradeoff: higher cost than Artix-7 boards

## Resource-Fit Guidance

- For small bring-up (8x8 to 16x16 systolic + light vector path):
  - Artix-7 100T/200T is acceptable.
- For block-sparse attention + KV cache studies with sustained throughput goals:
  - Prefer UltraScale+ class devices.

## IO and Memory Considerations

- Need stable DDR access path for realistic memory-stall studies.
- Reserve debug IO for counters/trace visibility.
- Keep clocking domains explicit early to avoid timing surprises later.
