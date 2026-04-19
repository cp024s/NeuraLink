module norm_unit #(
  parameter int DATA_W = 16
) (
  input  logic                      valid_i,
  input  logic [1:0]                mode_i, // batch/layer/instance (shared impl)
  input  logic signed [DATA_W-1:0]  vec_i [4],
  input  logic signed [DATA_W-1:0]  gamma_i,
  input  logic signed [DATA_W-1:0]  beta_i,
  output logic                      valid_o,
  output logic signed [DATA_W-1:0]  out_o [4]
);
  logic signed [DATA_W+2:0] mean;
  logic signed [DATA_W+3:0] var_approx;
  logic signed [DATA_W-1:0] inv_std;
  always_comb begin
    mean = (vec_i[0] + vec_i[1] + vec_i[2] + vec_i[3]) / 4;
    var_approx = (((vec_i[0]-mean)*(vec_i[0]-mean)) +
                  ((vec_i[1]-mean)*(vec_i[1]-mean)) +
                  ((vec_i[2]-mean)*(vec_i[2]-mean)) +
                  ((vec_i[3]-mean)*(vec_i[3]-mean))) / 4;
    inv_std = (var_approx > 1) ? DATA_W'(64 / var_approx) : 16'sd64;
    for (int i = 0; i < 4; i++) begin
      // mode_i reserved for future variants, current normalized affine path is shared.
      out_o[i] = (((vec_i[i] - mean) * inv_std * gamma_i) >>> 6) + beta_i + DATA_W'(mode_i);
    end
    valid_o = valid_i;
  end
endmodule
