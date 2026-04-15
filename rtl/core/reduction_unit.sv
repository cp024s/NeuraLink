module reduction_unit #(
  parameter int DATA_W = 16
) (
  input  logic                      valid_i,
  input  logic [2:0]                mode_i, // 0=sum,1=mean,2=max,3=min,4=argmax
  input  logic signed [DATA_W-1:0]  vec_i [4],
  output logic                      valid_o,
  output logic signed [DATA_W-1:0]  out_o
);
  logic signed [DATA_W+1:0] vsum;
  logic signed [DATA_W-1:0] vmax, vmin;
  logic [1:0] argmax_idx;
  always_comb begin
    vsum = '0;
    vmax = vec_i[0];
    vmin = vec_i[0];
    argmax_idx = 2'd0;
    for (int i = 0; i < 4; i++) begin
      vsum += vec_i[i];
      if (vec_i[i] > vmax) begin
        vmax = vec_i[i];
        argmax_idx = i[1:0];
      end
      if (vec_i[i] < vmin) vmin = vec_i[i];
    end
    valid_o = valid_i;
    unique case (mode_i)
      3'd0: out_o = vsum;
      3'd1: out_o = vsum / 4;
      3'd2: out_o = vmax;
      3'd3: out_o = vmin;
      default: out_o = DATA_W'(argmax_idx);
    endcase
  end
endmodule
