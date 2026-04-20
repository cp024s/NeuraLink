`timescale 1ns/1ps

module backpressure_controller_tb;
  logic clk;
  logic rst_n;
  logic enq;
  logic deq;
  logic [7:0] max_credit;
  logic stall;
  logic [7:0] credit_used;

  backpressure_controller #(.CREDIT_W(8)) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .enqueue_i(enq),
    .dequeue_i(deq),
    .max_credit_i(max_credit),
    .stall_o(stall),
    .credit_used_o(credit_used)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 0;
    rst_n = 0;
    enq = 0;
    deq = 0;
    max_credit = 8'd3;

    repeat (2) @(posedge clk);
    rst_n = 1;

    // Fill credits.
    repeat (3) begin
      @(posedge clk);
      enq = 1;
      deq = 0;
    end
    @(posedge clk);
    enq = 0;
    if (!stall) $fatal(1, "Expected stall after credit limit reached.");

    // Drain one credit and ensure stall drops.
    @(posedge clk);
    deq = 1;
    @(posedge clk);
    deq = 0;
    if (stall) $fatal(1, "Expected stall to clear after dequeue.");

    $display("backpressure_controller_tb passed");
    $finish;
  end
endmodule
