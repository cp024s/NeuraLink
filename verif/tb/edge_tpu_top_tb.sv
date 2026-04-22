`timescale 1ns/1ps
`include "accel_pkg.sv"

module edge_tpu_top_tb;
  import accel_pkg::*;

  localparam int ROWS = 4;
  localparam int COLS = 4;
  localparam int ACC_W = 24;

  logic clk;
  logic rst_n;
  logic start;
  tile_desc_t desc;
  logic busy;
  logic done;
  logic signed [ACC_W-1:0] result00;
  logic [31:0] pe_active_cycles;
  logic [31:0] pe_idle_cycles;
  logic [31:0] dma_stall_cycles;
  logic [31:0] noc_flit_count;

  edge_tpu_top #(
    .ROWS(ROWS),
    .COLS(COLS)
  ) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .start_i(start),
    .tile_desc_i(desc),
    .busy_o(busy),
    .done_o(done),
    .result00_o(result00),
    .pe_active_cycles_o(pe_active_cycles),
    .pe_idle_cycles_o(pe_idle_cycles),
    .dma_stall_cycles_o(dma_stall_cycles),
    .noc_flit_count_o(noc_flit_count)
  );

  always #5 clk = ~clk;

  task automatic pulse_start;
    begin
      @(posedge clk);
      start = 1'b1;
      @(posedge clk);
      start = 1'b0;
    end
  endtask

  initial begin
    int timeout;
    clk = 1'b0;
    rst_n = 1'b0;
    start = 1'b0;
    desc = '0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    desc.m = 16'd4;
    desc.n = 16'd4;
    desc.k = 16'd8;
    desc.a_base = 32'h0000_1000;
    desc.b_base = 32'h0000_2000;
    desc.c_base = 32'h0000_3000;
    desc.mode = DATAFLOW_OUTPUT_STATIONARY;
    desc.op_class = OP_GEMM;
    desc.sparse_en = 1'b0;

    pulse_start();

    timeout = 0;
    while (!done && timeout < 500) begin
      @(posedge clk);
      timeout++;
    end

    if (!done) begin
      $fatal(1, "Timed out waiting for done.");
    end
    if ($isunknown(result00)) begin
      $fatal(1, "result00 has unknown value.");
    end
    if (pe_active_cycles == 0) begin
      $fatal(1, "Expected PE activity but counter is zero.");
    end
    if (noc_flit_count == 0) begin
      $fatal(1, "Expected NoC flits but counter is zero.");
    end

    $display("TOP_TB done. result00=%0d pe_active=%0d noc_flits=%0d",
      result00, pe_active_cycles, noc_flit_count);
    $finish;
  end
endmodule
