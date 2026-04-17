if { $argc < 4 } {
  puts "Usage: vivado_project.tcl <root_dir> <build_dir> <top_module> <fpga_part>"
  exit 1
}

set ROOT_DIR   [lindex $argv 0]
set BUILD_DIR  [lindex $argv 1]
set TOP_MODULE [lindex $argv 2]
set FPGA_PART  [lindex $argv 3]

set PROJ_NAME  "neuralink_fpga"
set PROJ_DIR   "$BUILD_DIR/project"

file mkdir $BUILD_DIR
file mkdir $PROJ_DIR

create_project $PROJ_NAME $PROJ_DIR -force -part $FPGA_PART
set_property target_language Verilog [current_project]

read_verilog -sv "$ROOT_DIR/rtl/include/accel_pkg.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/mac_pe.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/pe_array.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/vector_unit.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/activation_pipe.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/conv2d_unit.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/pooling_unit.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/reduction_unit.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/norm_unit.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/math_unit.sv"
read_verilog -sv "$ROOT_DIR/rtl/core/precision_convert_unit.sv"
read_verilog -sv "$ROOT_DIR/rtl/interconnect/noc_router.sv"
read_verilog -sv "$ROOT_DIR/rtl/interconnect/data_switch.sv"
read_verilog -sv "$ROOT_DIR/rtl/system/tile_scheduler.sv"
read_verilog -sv "$ROOT_DIR/rtl/system/decoupled_issue_ctrl.sv"
read_verilog -sv "$ROOT_DIR/rtl/system/instruction_sequencer.sv"
read_verilog -sv "$ROOT_DIR/rtl/system/perf_counter_block.sv"
read_verilog -sv "$ROOT_DIR/rtl/system/riscv_coprocessor_bridge.sv"
read_verilog -sv "$ROOT_DIR/rtl/memory/bank_addr_mapper.sv"
read_verilog -sv "$ROOT_DIR/rtl/memory/pingpong_buffer_ctrl.sv"
read_verilog -sv "$ROOT_DIR/rtl/memory/scratchpad_bank.sv"
read_verilog -sv "$ROOT_DIR/rtl/memory/tile_dma.sv"
read_verilog -sv "$ROOT_DIR/rtl/top/edge_tpu_top.sv"

synth_design -top $TOP_MODULE -part $FPGA_PART -flatten_hierarchy rebuilt
opt_design
place_design
route_design

report_utilization -file "$BUILD_DIR/utilization.rpt"
report_timing_summary -file "$BUILD_DIR/timing_summary.rpt"
write_checkpoint -force "$BUILD_DIR/post_route.dcp"
write_edif -force "$BUILD_DIR/$TOP_MODULE.edf"

puts "Vivado TCL flow complete"
exit 0
