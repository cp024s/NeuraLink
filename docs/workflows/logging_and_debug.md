# Logging and Debug Workflow

NeuraLink uses color-coded logs in both shell scripts and Python tools to improve simulation readability.

## Log Types

- `INFO`: normal progress updates
- `WARN`: recoverable issue or fallback
- `ERROR`: hard failure path
- `DEBUG`: verbose details (enabled with `DEBUG=1`)
- `OK`: completed stage

## Shell Logging

Implemented in `scripts/common/logging.sh`.

Used by:

- `scripts/build_sim.sh`
- `scripts/run_config.sh`
- `scripts/run_sweep.sh`
- `scripts/run_demo.sh`
- `scripts/run_input_case.sh`
- `scripts/run_input_suite.sh`
- `scripts/run_plots.sh`
- `scripts/synth_check.sh`

## Python Logging

Implemented in `benchmarks/logging_utils.py`.

Used by benchmark/report scripts for consistent formatting.

## Environment Controls

- `DEBUG=1`: enable debug lines
- `NO_COLOR=1`: disable ANSI color sequences

Example:

```bash
DEBUG=1 make run
NO_COLOR=1 make demo
```
