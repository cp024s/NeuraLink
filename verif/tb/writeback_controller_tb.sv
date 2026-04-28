`timescale 1ns/1ps

module writeback_controller_tb;
  logic clk;
  logic rst_n;
  logic clear;
  logic push;
  logic [7:0] data_in;
  logic pop;
  logic [7:0] data_out;
  logic full, empty;
  logic [5:0] count;

  logic start;
  logic dma_done;
  logic wb_busy;
  logic wb_done;

  output_fifo #(
    .DATA_W(8),
    .DEPTH(32)
  ) u_fifo (
    .clk_i(clk),
    .rst_ni(rst_n),
    .clear_i(clear),
    .push_i(push),
    .data_i(data_in),
    .pop_i(pop),
    .data_o(data_out),
    .full_o(full),
    .empty_o(empty),
    .count_o(count)
  );

  writeback_controller u_wb (
    .clk_i(clk),
    .rst_ni(rst_n),
    .start_i(start),
    .fifo_empty_i(empty),
    .fifo_pop_o(pop),
    .dma_store_done_i(dma_done),
    .busy_o(wb_busy),
    .done_pulse_o(wb_done)
  );

  always #5 clk = ~clk;

  task automatic push_word(input [7:0] v);
    begin
      @(posedge clk);
      push <= 1'b1;
      data_in <= v;
      @(posedge clk);
      push <= 1'b0;
    end
  endtask

  initial begin
    int timeout;
    clk = 1'b0;
    rst_n = 1'b0;
    clear = 1'b0;
    push = 1'b0;
    data_in = '0;
    start = 1'b0;
    dma_done = 1'b0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    push_word(8'h11);
    push_word(8'h22);
    push_word(8'h33);

    @(posedge clk);
    start <= 1'b1;
    @(posedge clk);
    start <= 1'b0;

    repeat (5) @(posedge clk);
    dma_done <= 1'b1;
    @(posedge clk);
    dma_done <= 1'b0;

    timeout = 0;
    while (!wb_done && timeout < 60) begin
      @(posedge clk);
      timeout++;
    end

    if (!wb_done) begin
      $fatal(1, "Writeback controller did not complete.");
    end
    if (!empty) begin
      $fatal(1, "FIFO must be empty at writeback completion.");
    end

    $display("WB_TB PASS count=%0d busy=%0b", count, wb_busy);
    $finish;
  end
endmodule

