module conv2d_unit #(
  parameter int DATA_W = 8
) (
  input  logic                           valid_i,
  input  logic                           depthwise_i,
  input  logic signed [DATA_W-1:0]       win_i [9],
  input  logic signed [DATA_W-1:0]       ker_i [9],
  output logic                           valid_o,
  output logic signed [2*DATA_W+4:0]     out_o
);
  logic signed [2*DATA_W+4:0] acc;
  always_comb begin
    acc = '0;
    for (int i = 0; i < 9; i++) begin
      if (depthwise_i) begin
        if (i % 2 == 0) acc += win_i[i] * ker_i[i];
      end else begin
        acc += win_i[i] * ker_i[i];
      end
    end
    valid_o = valid_i;
    out_o = acc;
  end
endmodule
