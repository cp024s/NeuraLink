`timescale 1ns/1ps

module op_units_tb;
  logic valid;
  logic depthwise;
  logic signed [7:0] win [9];
  logic signed [7:0] ker [9];
  logic conv_valid;
  logic signed [20:0] conv_out;

  logic [1:0] pool_mode;
  logic signed [15:0] pool_vec [4];
  logic pool_valid;
  logic signed [15:0] pool_out;

  logic [2:0] red_mode;
  logic signed [15:0] red_vec [4];
  logic red_valid;
  logic signed [15:0] red_out;

  logic [1:0] math_mode;
  logic signed [15:0] math_in;
  logic math_valid;
  logic signed [15:0] math_out;

  logic [1:0] pc_mode;
  logic signed [15:0] pc_in;
  logic signed [7:0] pc_scale;
  logic pc_valid;
  logic signed [15:0] pc_out;

  conv2d_unit u_conv(
    .valid_i(valid), .depthwise_i(depthwise), .win_i(win), .ker_i(ker),
    .valid_o(conv_valid), .out_o(conv_out)
  );
  pooling_unit u_pool(
    .valid_i(valid), .mode_i(pool_mode), .vec_i(pool_vec),
    .valid_o(pool_valid), .out_o(pool_out)
  );
  reduction_unit u_red(
    .valid_i(valid), .mode_i(red_mode), .vec_i(red_vec),
    .valid_o(red_valid), .out_o(red_out)
  );
  math_unit u_math(
    .valid_i(valid), .mode_i(math_mode), .data_i(math_in),
    .valid_o(math_valid), .out_o(math_out)
  );
  precision_convert_unit u_prec(
    .valid_i(valid), .mode_i(pc_mode), .data_i(pc_in), .scale_i(pc_scale),
    .valid_o(pc_valid), .out_o(pc_out)
  );

  initial begin
    valid = 1'b1;
    depthwise = 1'b0;
    for (int i = 0; i < 9; i++) begin
      win[i] = i + 1;
      ker[i] = 1;
    end
    pool_vec[0] = 3; pool_vec[1] = 7; pool_vec[2] = 2; pool_vec[3] = 4;
    red_vec[0] = 1; red_vec[1] = 2; red_vec[2] = 3; red_vec[3] = 4;
    pool_mode = 2'd0;
    red_mode = 3'd0;
    math_mode = 2'd2;
    math_in = 16'sd25;
    pc_mode = 2'd0;
    pc_in = 16'sd200;
    pc_scale = 8'sd4;
    #1;
    if (!conv_valid || conv_out <= 0) $fatal(1, "conv2d_unit failed");
    if (!pool_valid || pool_out != 16'sd7) $fatal(1, "pooling_unit failed");
    if (!red_valid || red_out != 16'sd10) $fatal(1, "reduction_unit failed");
    if (!math_valid || math_out <= 0) $fatal(1, "math_unit failed");
    if (!pc_valid || pc_out != 16'sd127) $fatal(1, "precision_convert_unit failed");
    $display("op_units_tb passed");
    $finish;
  end
endmodule
