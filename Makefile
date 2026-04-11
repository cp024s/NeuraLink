SHELL := /bin/bash
ROOT := $(abspath .)
RESULTS_DIR ?= $(ROOT)/results/latest
CONFIG ?= $(ROOT)/configs/demo_configs.json
INPUT_CONFIG ?= $(ROOT)/configs/input_case.json
INPUT_OUT ?= $(ROOT)/results/input_case_latest
ROWS_LIST ?= 4,8,12
COLS_LIST ?= 4,8,12
K_LIST ?= 16,32,64
WARMUP ?= 4
MAXBW ?= 64
RANDOM_SAMPLES ?= 6
SEED ?= 7
BASELINE_CONFIG ?= $(ROOT)/configs/baseline_equivalent.json
CAPABILITY_CONFIG ?= $(ROOT)/configs/capability_matrix.json

.PHONY: help build smoke op_tb issue_tb system_tb synth_check run sweep report plots html_report input input_suite demo refs clean distclean dynamic_run ui

help:
	@echo "Targets:"
	@echo "  make build        - Compile simulation binary"
	@echo "  make smoke        - Run legacy smoke test"
	@echo "  make op_tb        - Run RTL op-unit testbench (conv/pool/reduce/math/precision)"
	@echo "  make issue_tb     - Run decoupled load/compute/store controller testbench"
	@echo "  make system_tb    - Run command-driven top-level accelerator testbench"
	@echo "  make synth_check  - Run yosys synthesis/lint gate for edge_tpu_top (if yosys is installed)"
	@echo "  make run          - Run benchmark sweep using CONFIG"
	@echo "  make dynamic_run  - Run runtime-generated benchmark sweep (ROWS_LIST,COLS_LIST,K_LIST)"
	@echo "  make report       - Generate markdown report from RESULTS_DIR/metrics.csv"
	@echo "  make plots        - Generate SVG charts from RESULTS_DIR/metrics.csv"
	@echo "  make html_report  - Generate complete HTML report with plots and raw data"
	@echo "  make input        - Run data-driven input case from INPUT_CONFIG"
	@echo "  make input_suite  - Run diverse predefined input cases"
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

op_tb:
	@mkdir -p $(ROOT)/build
	@iverilog -g2012 -o $(ROOT)/build/op_units_tb.out \
		$(ROOT)/rtl/core/conv2d_unit.sv \
		$(ROOT)/rtl/core/pooling_unit.sv \
		$(ROOT)/rtl/core/reduction_unit.sv \
		$(ROOT)/rtl/core/math_unit.sv \
		$(ROOT)/rtl/core/precision_convert_unit.sv \
		$(ROOT)/verif/tb/op_units_tb.sv
	@vvp $(ROOT)/build/op_units_tb.out

issue_tb:
	@mkdir -p $(ROOT)/build
	@iverilog -g2012 -o $(ROOT)/build/decoupled_issue_ctrl_tb.out \
		$(ROOT)/rtl/system/decoupled_issue_ctrl.sv \
		$(ROOT)/verif/tb/decoupled_issue_ctrl_tb.sv
	@vvp $(ROOT)/build/decoupled_issue_ctrl_tb.out

system_tb:
	@mkdir -p $(ROOT)/build
	@iverilog -g2012 -I$(ROOT)/rtl/include -o $(ROOT)/build/edge_tpu_top_tb.out \
		$(ROOT)/rtl/include/accel_pkg.sv \
		$(ROOT)/rtl/core/mac_pe.sv \
		$(ROOT)/rtl/core/pe_array.sv \
		$(ROOT)/rtl/core/vector_unit.sv \
		$(ROOT)/rtl/core/activation_pipe.sv \
		$(ROOT)/rtl/core/conv2d_unit.sv \
		$(ROOT)/rtl/core/pooling_unit.sv \
		$(ROOT)/rtl/core/reduction_unit.sv \
		$(ROOT)/rtl/core/norm_unit.sv \
		$(ROOT)/rtl/core/math_unit.sv \
		$(ROOT)/rtl/core/precision_convert_unit.sv \
		$(ROOT)/rtl/interconnect/noc_router.sv \
		$(ROOT)/rtl/interconnect/data_switch.sv \
		$(ROOT)/rtl/system/tile_scheduler.sv \
		$(ROOT)/rtl/system/decoupled_issue_ctrl.sv \
		$(ROOT)/rtl/system/instruction_sequencer.sv \
		$(ROOT)/rtl/system/perf_counter_block.sv \
		$(ROOT)/rtl/memory/bank_addr_mapper.sv \
		$(ROOT)/rtl/memory/pingpong_buffer_ctrl.sv \
		$(ROOT)/rtl/memory/tile_dma.sv \
		$(ROOT)/rtl/top/edge_tpu_top.sv \
		$(ROOT)/verif/tb/edge_tpu_top_tb.sv
	@timeout 20s vvp $(ROOT)/build/edge_tpu_top_tb.out || (echo "system_tb timed out; inspect top-level control/dataflow path." && exit 1)

synth_check:
	@$(ROOT)/scripts/synth_check.sh

run: build
	@$(ROOT)/scripts/run_sweep.sh $(CONFIG) $(RESULTS_DIR)
	@$(ROOT)/scripts/run_plots.sh $(RESULTS_DIR)/metrics.csv $(RESULTS_DIR)
	@python3 $(ROOT)/benchmarks/metrics_report.py \
		--input $(RESULTS_DIR)/metrics.csv \
		--output $(RESULTS_DIR)/summary.md
	@python3 $(ROOT)/benchmarks/baseline_compare.py \
		--metrics-csv $(RESULTS_DIR)/metrics.csv \
		--baseline-json $(BASELINE_CONFIG) \
		--out-json $(RESULTS_DIR)/baseline_comparison.json
	@python3 $(ROOT)/benchmarks/html_report.py \
		--metrics-csv $(RESULTS_DIR)/metrics.csv \
		--comparison-json $(RESULTS_DIR)/baseline_comparison.json \
		--capability-json $(CAPABILITY_CONFIG) \
		--out-html $(RESULTS_DIR)/benchmark_report.html \
		--title "NeuraLink Benchmark Report"

dynamic_run: build
	@DYNAMIC_SWEEP=1 \
	ROWS_LIST="$(ROWS_LIST)" \
	COLS_LIST="$(COLS_LIST)" \
	K_LIST="$(K_LIST)" \
	WARMUP="$(WARMUP)" \
	MAXBW="$(MAXBW)" \
	RANDOM_SAMPLES="$(RANDOM_SAMPLES)" \
	SEED="$(SEED)" \
	$(ROOT)/scripts/run_sweep.sh $(CONFIG) $(RESULTS_DIR)
	@$(ROOT)/scripts/run_plots.sh $(RESULTS_DIR)/metrics.csv $(RESULTS_DIR)
	@python3 $(ROOT)/benchmarks/metrics_report.py \
		--input $(RESULTS_DIR)/metrics.csv \
		--output $(RESULTS_DIR)/summary.md
	@python3 $(ROOT)/benchmarks/baseline_compare.py \
		--metrics-csv $(RESULTS_DIR)/metrics.csv \
		--baseline-json $(BASELINE_CONFIG) \
		--out-json $(RESULTS_DIR)/baseline_comparison.json
	@python3 $(ROOT)/benchmarks/html_report.py \
		--metrics-csv $(RESULTS_DIR)/metrics.csv \
		--comparison-json $(RESULTS_DIR)/baseline_comparison.json \
		--capability-json $(CAPABILITY_CONFIG) \
		--out-html $(RESULTS_DIR)/benchmark_report.html \
		--title "NeuraLink Benchmark Report"

report:
	@python3 $(ROOT)/benchmarks/metrics_report.py \
		--input $(RESULTS_DIR)/metrics.csv \
		--output $(RESULTS_DIR)/summary.md
	@echo "Report: $(RESULTS_DIR)/summary.md"

plots:
	@$(ROOT)/scripts/run_plots.sh $(RESULTS_DIR)/metrics.csv $(RESULTS_DIR)

html_report:
	@python3 $(ROOT)/benchmarks/html_report.py \
		--metrics-csv $(RESULTS_DIR)/metrics.csv \
		--comparison-json $(RESULTS_DIR)/baseline_comparison.json \
		--capability-json $(CAPABILITY_CONFIG) \
		--out-html $(RESULTS_DIR)/benchmark_report.html \
		--title "NeuraLink Benchmark Report"

input:
	@$(ROOT)/scripts/run_input_case.sh $(INPUT_CONFIG) $(INPUT_OUT)

input_suite:
	@$(ROOT)/scripts/run_input_suite.sh

demo:
	@$(ROOT)/scripts/run_demo.sh

ui:
	@python3 $(ROOT)/benchmarks/web_ui_server.py --port 8080 --root $(ROOT)

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
