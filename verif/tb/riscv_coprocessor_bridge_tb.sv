`timescale 1ns/1ps
`include "accel_pkg.sv"

module riscv_coprocessor_bridge_tb;
  import accel_pkg::*;

  logic clk;
  logic rst_n;
  logic mmio_valid;
  logic mmio_we;
  logic [7:0] mmio_addr;
  logic [31:0] mmio_wdata;
  logic [31:0] mmio_rdata;
  logic mmio_ready;
  logic irq;
  logic accel_start;
  tile_desc_t accel_desc;
  logic accel_busy;
  logic accel_done;

  riscv_coprocessor_bridge dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .mmio_valid_i(mmio_valid),
    .mmio_we_i(mmio_we),
    .mmio_addr_i(mmio_addr),
    .mmio_wdata_i(mmio_wdata),
    .mmio_rdata_o(mmio_rdata),
    .mmio_ready_o(mmio_ready),
    .irq_o(irq),
    .accel_start_o(accel_start),
    .accel_desc_o(accel_desc),
    .accel_busy_i(accel_busy),
    .accel_done_i(accel_done),
    .perf_active_cycles_i(32'd10),
    .perf_idle_cycles_i(32'd2),
    .perf_dma_stall_cycles_i(32'd1),
    .perf_noc_flits_i(32'd6)
  );

  always #5 clk = ~clk;

  task automatic mmio_write(input logic [7:0] addr, input logic [31:0] data);
    begin
      @(posedge clk);
      mmio_valid <= 1'b1;
      mmio_we <= 1'b1;
      mmio_addr <= addr;
      mmio_wdata <= data;
      @(posedge clk);
      mmio_valid <= 1'b0;
      mmio_we <= 1'b0;
    end
  endtask

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    mmio_valid = 1'b0;
    mmio_we = 1'b0;
    mmio_addr = '0;
    mmio_wdata = '0;
    accel_busy = 1'b0;
    accel_done = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;

    mmio_write(8'h08, {16'd8, 16'd8});   // m,n
    mmio_write(8'h18, {16'd16, 16'd0});  // k,mode
    mmio_write(8'h0c, 32'h1000_0000);    // a_base
    mmio_write(8'h10, 32'h2000_0000);    // b_base
    mmio_write(8'h14, 32'h3000_0000);    // c_base
    mmio_write(8'h1c, 32'h0000_0000);    // op_class
    mmio_write(8'h00, 32'h0000_0003);    // start + irq_en

    @(posedge clk);
    if (!accel_start) $fatal(1, "Expected accel_start pulse.");

    accel_busy <= 1'b1;
    repeat (3) @(posedge clk);
    accel_done <= 1'b1;
    @(posedge clk);
    accel_done <= 1'b0;
    accel_busy <= 1'b0;

    repeat (2) @(posedge clk);
    if (!irq) $fatal(1, "Expected IRQ after done.");
    if (accel_desc.m != 16'd8 || accel_desc.n != 16'd8 || accel_desc.k != 16'd16) begin
      $fatal(1, "Descriptor fields mismatch.");
    end

    $display("riscv_coprocessor_bridge_tb passed");
    $finish;
  end
endmodule
