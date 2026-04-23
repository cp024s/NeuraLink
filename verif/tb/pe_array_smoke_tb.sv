`timescale 1ns/1ps

module pe_array_smoke_tb;
  localparam int ROWS = 2;
  localparam int COLS = 2;
  localparam int DATA_W = 8;
  localparam int ACC_W = 24;

  logic clk;
  logic rst_n;
  logic clear_i;
  logic signed [DATA_W-1:0] a_west [ROWS];
  logic signed [DATA_W-1:0] b_north [COLS];
  logic a_valid_west [ROWS];
  logic b_valid_north [COLS];
  logic signed [ACC_W-1:0] acc [ROWS][COLS];
  logic acc_valid [ROWS][COLS];

  pe_array #(
    .ROWS(ROWS),
    .COLS(COLS),
    .DATA_W(DATA_W),
    .ACC_W(ACC_W)
  ) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .clear_i(clear_i),
    .a_west_i(a_west),
    .b_north_i(b_north),
    .a_valid_west_i(a_valid_west),
    .b_valid_north_i(b_valid_north),
    .acc_o(acc),
    .acc_valid_o(acc_valid)
  );

  always #5 clk = ~clk;

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    clear_i = 1'b0;
    for (int i = 0; i < ROWS; i++) begin
      a_west[i] = '0;
      a_valid_west[i] = 1'b0;
    end
    for (int j = 0; j < COLS; j++) begin
      b_north[j] = '0;
      b_valid_north[j] = 1'b0;
    end

    repeat (2) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    clear_i = 1'b1;
    @(posedge clk);
    clear_i = 1'b0;

    // Pulse a single multiply wave into row0/col0.
    @(posedge clk);
    a_west[0] = 8'sd3;
    b_north[0] = 8'sd2;
    a_valid_west[0] = 1'b1;
    b_valid_north[0] = 1'b1;

    @(posedge clk);
    a_valid_west[0] = 1'b0;
    b_valid_north[0] = 1'b0;

    repeat (6) @(posedge clk);

    $display("Smoke test complete. acc00=%0d unknown=%0d", acc[0][0], $isunknown(acc[0][0]));
    $finish;
  end
endmodule
