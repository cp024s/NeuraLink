set root_dir $::env(ROOT_DIR)
set build_dir $::env(BUILD_DIR)
set top_module $::env(TOP_MODULE)
set pdk_name $::env(PDK_NAME)

set netlist "$build_dir/${top_module}_synth.v"
set report_dir "$build_dir/reports"
file mkdir $report_dir

if {![file exists $netlist]} {
  puts "ERROR: synthesized netlist not found at $netlist"
  exit 1
}

# Research-mode PD scaffold:
# This script is process-node agnostic by design and expects node collateral
# (LEF/Liberty/Tech LEF/RCX) to be provided via environment variables.
set tech_lef [expr {[info exists ::env(TECH_LEF)] ? $::env(TECH_LEF) : ""}]
set stdcell_lef [expr {[info exists ::env(STDCELL_LEF)] ? $::env(STDCELL_LEF) : ""}]
set stdcell_lib [expr {[info exists ::env(STDCELL_LIB)] ? $::env(STDCELL_LIB) : ""}]

if {$tech_lef eq "" || $stdcell_lef eq "" || $stdcell_lib eq ""} {
  puts "WARNING: LEF/Liberty not provided. Running netlist checks only."
  read_verilog $netlist
  link_design $top_module
  report_checks -path_delay max > "$report_dir/timing_placeholder.rpt"
  report_design_area > "$report_dir/area_placeholder.rpt"
  puts "PD placeholder checks complete. Provide TECH_LEF/STDCELL_LEF/STDCELL_LIB for full flow."
  exit 0
}

read_lef $tech_lef
read_lef $stdcell_lef
read_liberty $stdcell_lib
read_verilog $netlist
link_design $top_module

initialize_floorplan -die_area "0 0 1200 1200" -core_area "100 100 1100 1100"
place_pins -random
global_placement
detailed_placement
estimate_parasitics -placement
report_checks -path_delay max > "$report_dir/post_place_timing.rpt"
report_design_area > "$report_dir/post_place_area.rpt"

# Routing commands are enabled when full PDK collateral is available.
global_route
detailed_route
estimate_parasitics -global_routing
report_checks -path_delay max > "$report_dir/post_route_timing.rpt"

write_def "$build_dir/${top_module}.def"
write_verilog "$build_dir/${top_module}_pd.v"
write_db "$build_dir/${top_module}.odb"

puts "OpenROAD flow complete for PDK=$pdk_name"
