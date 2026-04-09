`include "accel_pkg.sv"

module edge_tpu_top #(
  parameter int ROWS = 4,
  parameter int COLS = 4
) (
  input logic clk_i,
  input logic rst_ni
);
  import accel_pkg::*;

  logic clear_array;
  logic signed [DATA_W-1:0] a_west [ROWS];
  logic signed [DATA_W-1:0] b_north [COLS];
  logic a_valid_west [ROWS];
  logic b_valid_north [COLS];
  logic signed [ACC_W-1:0] acc [ROWS][COLS];
  logic acc_valid [ROWS][COLS];
  logic [31:0] pe_active_cycles;
  logic [31:0] pe_idle_cycles;
  logic [31:0] dma_stall_cycles;
  logic [31:0] noc_flit_count;

  logic noc_in_valid, noc_in_ready, noc_out_valid, noc_out_ready;
  logic [63:0] noc_in_flit, noc_out_flit;

  // Placeholder control defaults for early integration bring-up.
  always_comb begin
    clear_array = 1'b0;
    for (int r = 0; r < ROWS; r++) begin
      a_west[r] = '0;
      a_valid_west[r] = 1'b0;
    end
    for (int c = 0; c < COLS; c++) begin
      b_north[c] = '0;
      b_valid_north[c] = 1'b0;
    end
  end

  pe_array #(
    .ROWS(ROWS),
    .COLS(COLS),
    .DATA_W(DATA_W),
    .ACC_W(ACC_W)
  ) u_array (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .clear_i(clear_array),
    .a_west_i(a_west),
    .b_north_i(b_north),
    .a_valid_west_i(a_valid_west),
    .b_valid_north_i(b_valid_north),
    .acc_o(acc),
    .acc_valid_o(acc_valid)
  );

  // NoC and counters are integrated early so instrumentation is available
  // as architecture complexity increases.
  assign noc_in_valid = 1'b0;
  assign noc_in_flit = '0;
  assign noc_out_ready = 1'b1;

  noc_router u_noc_router (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .in_valid_i(noc_in_valid),
    .in_flit_i(noc_in_flit),
    .in_ready_o(noc_in_ready),
    .out_valid_o(noc_out_valid),
    .out_flit_o(noc_out_flit),
    .out_ready_i(noc_out_ready)
  );

  perf_counter_block u_perf_counter_block (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .enable_i(1'b1),
    .pe_active_i(acc_valid[0][0]),
    .dma_stall_i(1'b0),
    .noc_flits_i(noc_out_valid ? 16'd1 : 16'd0),
    .pe_active_cycles_o(pe_active_cycles),
    .pe_idle_cycles_o(pe_idle_cycles),
    .dma_stall_cycles_o(dma_stall_cycles),
    .noc_flit_count_o(noc_flit_count)
  );

  // TODO:
  // 1) Connect tile scheduler + DMA
  // 2) Add scratchpad interfaces
  // 3) Expose performance counters over CSR bus
endmodule
