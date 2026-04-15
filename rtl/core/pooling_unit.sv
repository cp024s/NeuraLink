module pooling_unit #(
  parameter int DATA_W = 16
) (
  input  logic                      valid_i,
  input  logic [1:0]                mode_i, // 0=max,1=avg,2=global(max)
  input  logic signed [DATA_W-1:0]  vec_i [4],
  output logic                      valid_o,
  output logic signed [DATA_W-1:0]  out_o
);
  logic signed [DATA_W-1:0] vmax;
  logic signed [DATA_W+1:0] vsum;
  always_comb begin
    vmax = vec_i[0];
    vsum = '0;
    for (int i = 0; i < 4; i++) begin
      if (vec_i[i] > vmax) vmax = vec_i[i];
      vsum += vec_i[i];
    end
    valid_o = valid_i;
    unique case (mode_i)
      2'd0: out_o = vmax;
      2'd1: out_o = vsum / 4;
      default: out_o = vmax;
    endcase
  end
endmodule
