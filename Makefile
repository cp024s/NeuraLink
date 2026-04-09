SHELL := /bin/bash
ROOT := $(abspath .)
RESULTS_DIR ?= $(ROOT)/results/latest
CONFIG ?= $(ROOT)/configs/demo_configs.json
INPUT_CONFIG ?= $(ROOT)/configs/input_case.json
INPUT_OUT ?= $(ROOT)/results/input_case_latest

.PHONY: help build smoke run sweep report plots input demo refs clean distclean

help:
	@echo "Targets:"
	@echo "  make build        - Compile simulation binary"
	@echo "  make smoke        - Run legacy smoke test"
	@echo "  make run          - Run benchmark sweep using CONFIG"
	@echo "  make report       - Generate markdown report from RESULTS_DIR/metrics.csv"
	@echo "  make plots        - Generate PNG charts from RESULTS_DIR/metrics.csv"
	@echo "  make input        - Run data-driven input case from INPUT_CONFIG"
	@echo "  make demo         - End-to-end build+sweep+report"
	@echo "  make refs         - Clone/update reference accelerator repositories"
	@echo "  make clean        - Remove generated logs, builds, charts, and all results"
	@echo "  make distclean    - clean + remove cloned third_party repositories"

build:
	@$(ROOT)/scripts/build_sim.sh

smoke:
	@mkdir -p $(ROOT)/build
	@iverilog -g2012 -o $(ROOT)/build/pe_smoke.out \
		$(ROOT)/rtl/core/mac_pe.sv \
		$(ROOT)/rtl/core/pe_array.sv \
		$(ROOT)/verif/tb/pe_array_smoke_tb.sv
	@vvp $(ROOT)/build/pe_smoke.out

run: build
	@$(ROOT)/scripts/run_sweep.sh $(CONFIG) $(RESULTS_DIR)
	@$(ROOT)/scripts/run_plots.sh $(RESULTS_DIR)/metrics.csv $(RESULTS_DIR)

report:
	@python3 $(ROOT)/benchmarks/metrics_report.py \
		--input $(RESULTS_DIR)/metrics.csv \
		--output $(RESULTS_DIR)/summary.md
	@echo "Report: $(RESULTS_DIR)/summary.md"

plots:
	@$(ROOT)/scripts/run_plots.sh $(RESULTS_DIR)/metrics.csv $(RESULTS_DIR)

input:
	@$(ROOT)/scripts/run_input_case.sh $(INPUT_CONFIG) $(INPUT_OUT)

demo:
	@$(ROOT)/scripts/run_demo.sh

refs:
	@$(ROOT)/third_party/fetch_references.sh

clean:
	@echo "Cleaning generated artifacts..."
	@rm -rf $(ROOT)/build
	@rm -rf $(ROOT)/results/*
	@find $(ROOT) -type d -name "__pycache__" -prune -exec rm -rf {} +
	@find $(ROOT) -type f \( -name "*.out" -o -name "*.log" -o -name "*.vcd" -o -name "*.fsdb" -o -name "*.pyc" \) -delete
	@echo "Clean complete. Fresh state ready."

distclean: clean
	@rm -rf $(ROOT)/third_party/repos
	@echo "Distclean complete."
