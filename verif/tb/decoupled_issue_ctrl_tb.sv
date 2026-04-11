`timescale 1ns/1ps

module decoupled_issue_ctrl_tb;
  logic clk;
  logic rst_n;
  logic sched_valid;
  logic load_done;
  logic compute_done;
  logic store_done;
  logic can_compute;
  logic sched_pop;
  logic load_start;
  logic compute_start;
  logic store_start;
  logic busy;
  logic done_pulse;

  decoupled_issue_ctrl dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .sched_valid_i(sched_valid),
    .load_done_i(load_done),
    .compute_done_i(compute_done),
    .store_done_i(store_done),
    .can_compute_i(can_compute),
    .sched_pop_o(sched_pop),
    .load_start_o(load_start),
    .compute_start_o(compute_start),
    .store_start_o(store_start),
    .busy_o(busy),
    .done_pulse_o(done_pulse)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    sched_valid = 1'b0;
    load_done = 1'b0;
    compute_done = 1'b0;
    store_done = 1'b0;
    can_compute = 1'b0;

    repeat (2) @(posedge clk);
    rst_n = 1'b1;

    sched_valid = 1'b1;
    @(posedge clk);
    sched_valid = 1'b0;
    if (!(sched_pop && load_start)) $fatal(1, "Expected sched_pop/load_start pulse");

    repeat (2) @(posedge clk);
    load_done = 1'b1;
    @(posedge clk);
    load_done = 1'b0;

    can_compute = 1'b1;
    @(posedge clk);
    if (!compute_start) $fatal(1, "Expected compute_start pulse");
    can_compute = 1'b0;

    repeat (3) @(posedge clk);
    compute_done = 1'b1;
    @(posedge clk);
    compute_done = 1'b0;
    if (!store_start) $fatal(1, "Expected store_start pulse");

    repeat (2) @(posedge clk);
    store_done = 1'b1;
    @(posedge clk);
    store_done = 1'b0;
    if (!done_pulse) $fatal(1, "Expected done_pulse");

    @(posedge clk);
    if (busy) $fatal(1, "Controller should return idle");
    $display("decoupled_issue_ctrl_tb passed");
    $finish;
  end
endmodule
