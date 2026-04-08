# Research-Grade Edge TPU Accelerator Project

This repository is a demo-ready accelerator development framework focused on:
- Memory-aware architecture decisions.
- Scalable and modular RTL.
- Reproducible performance benchmarking and reporting.

## Project maturity

This is an **early-stage proof of work**, not a production-ready milestone.
It is intentionally structured for fast architectural iteration, validation, and stakeholder demos.

## What is included

- Research blueprint and architecture notes:
  - `docs/research_grade_accelerator_blueprint.md`
  - `docs/architecture/reference_integration_plan.md`
- Modular RTL scaffolding:
  - PE and PE array (`rtl/core`)
  - Memory primitives and DMA template (`rtl/memory`)
  - Integration shell (`rtl/top`)
- Verification starter assets:
  - Smoke and benchmark testbenches (`verif/tb`)
  - Assertion scaffold (`verif/sva`)
- Benchmark automation:
  - `benchmarks/benchmark_runner.py`
  - `benchmarks/metrics_report.py`
- End-to-end scripts and orchestration:
  - `scripts/*.sh`
  - `Makefile`

## Quick start

```bash
make build
make run
make report
make plots
```

Or run full demo:

```bash
make demo
```

Run a data-driven input case (matrix CSV inputs -> output matrix + visualizations):

```bash
make input
```

Run with a custom input-case config:

```bash
make input INPUT_CONFIG=/absolute/path/to/input_case.json INPUT_OUT=results/my_case
```

## Outputs

By default, sweep outputs are written to:
- `results/latest/metrics.json`
- `results/latest/metrics.csv`
- `results/latest/*.log`

Report generation writes:
- `results/latest/summary.md`

Plot generation writes:
- `results/latest/throughput_by_config.svg`
- `results/latest/latency_by_config.svg`
- `results/latest/efficiency_vs_bandwidth.svg`

Input-case generation writes:
- `results/input_case_latest/*_output.csv`
- `results/input_case_latest/*_output_heatmap.svg`
- `results/input_case_latest/*_metrics_chart.svg`

`make demo` writes to a timestamped folder under `results/`.

## Metrics captured

- `latency_cycles`
- `throughput_ops_per_cycle`
- `efficiency`
- `bandwidth_utilization`
- `pipeline_depth`
- `total_mac_ops`

## Reference repositories

Clone/update curated references:

```bash
make refs
```

For heavy industrial repository pull (optional):

```bash
INCLUDE_HEAVY=1 make refs
```

Use your local reference folder (`D:\Repositories\ref_repos`) instead of remote clone:

```bash
USE_LOCAL_REF_REPOS=1 make refs
```

## Resetting state

For a fresh run state:

```bash
make clean
```

For a deep reset including downloaded/cloned references:

```bash
make distclean
```

## Notes

- Current benchmark flow is cycle-analytic and simulation-backed, suitable for comparative studies.
- FPGA mapping is planned as phase-2 after RTL and instrumentation maturity.
