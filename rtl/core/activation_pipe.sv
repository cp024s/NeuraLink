module activation_pipe #(
  parameter int DATA_W = 8
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     valid_i,
  input  logic signed [DATA_W-1:0] data_i,
  output logic                     valid_o,
  output logic signed [DATA_W-1:0] data_o
);
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_o <= 1'b0;
      data_o <= '0;
    end else begin
      valid_o <= valid_i;
      data_o <= (data_i > 0) ? data_i : '0;
    end
  end
endmodule
