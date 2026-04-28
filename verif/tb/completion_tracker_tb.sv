`timescale 1ns/1ps

module completion_tracker_tb;
  logic clk;
  logic rst_n;
  logic alloc;
  logic compute_done;
  logic writeback_done;
  logic inflight;
  logic retire_pulse;
  logic [31:0] retired_count;

  completion_tracker u_completion_tracker (
    .clk_i(clk),
    .rst_ni(rst_n),
    .alloc_i(alloc),
    .compute_done_i(compute_done),
    .writeback_done_i(writeback_done),
    .inflight_o(inflight),
    .retire_pulse_o(retire_pulse),
    .retired_count_o(retired_count)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    alloc = 1'b0;
    compute_done = 1'b0;
    writeback_done = 1'b0;

    repeat (3) @(posedge clk);
    rst_n = 1'b1;

    // Allocate one tile.
    @(posedge clk);
    alloc <= 1'b1;
    @(posedge clk);
    alloc <= 1'b0;

    // Compute done first, then writeback done.
    @(posedge clk);
    compute_done <= 1'b1;
    @(posedge clk);
    compute_done <= 1'b0;
    @(posedge clk);
    writeback_done <= 1'b1;
    @(posedge clk);
    writeback_done <= 1'b0;

    @(posedge clk);
    if (retired_count != 1) begin
      $fatal(1, "Expected retired_count=1, got %0d", retired_count);
    end
    if (inflight) begin
      $fatal(1, "Expected no inflight tile after retire.");
    end

    // Allocate a second tile and complete in one cycle (simultaneous done signals).
    @(posedge clk);
    alloc <= 1'b1;
    @(posedge clk);
    alloc <= 1'b0;
    compute_done <= 1'b1;
    writeback_done <= 1'b1;
    @(posedge clk);
    compute_done <= 1'b0;
    writeback_done <= 1'b0;

    @(posedge clk);
    if (retired_count != 2) begin
      $fatal(1, "Expected retired_count=2, got %0d", retired_count);
    end

    $display("COMPLETION_TB PASS retired=%0d", retired_count);
    $finish;
  end
endmodule

