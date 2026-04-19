module vector_unit #(
  parameter int LANES = 4,
  parameter int DATA_W = 8
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     valid_i,
  input  logic [4:0]               op_i,
  input  logic signed [DATA_W-1:0] vec_a_i [LANES],
  input  logic signed [DATA_W-1:0] vec_b_i [LANES],
  output logic                     valid_o,
  output logic signed [DATA_W-1:0] vec_o [LANES]
);
  logic signed [DATA_W-1:0] clip_hi;
  logic signed [DATA_W-1:0] clip_lo;
  logic signed [DATA_W-1:0] x;

  assign clip_hi = 8'sd24;
  assign clip_lo = -8'sd24;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_o <= 1'b0;
      for (int l = 0; l < LANES; l++) begin
        vec_o[l] <= '0;
      end
    end else begin
      valid_o <= valid_i;
      for (int l = 0; l < LANES; l++) begin
        x = vec_a_i[l];
        unique case (op_i)
          5'd0: vec_o[l] <= vec_a_i[l] + vec_b_i[l]; // add
          5'd1: vec_o[l] <= vec_a_i[l] * vec_b_i[l]; // mul
          5'd2: vec_o[l] <= vec_a_i[l] * 8'sd2;      // scale
          5'd3: vec_o[l] <= (vec_a_i[l] > clip_hi) ? clip_hi : vec_a_i[l]; // clip hi
          5'd4: vec_o[l] <= (vec_a_i[l] < clip_lo) ? clip_lo : vec_a_i[l]; // clip lo
          5'd5: vec_o[l] <= (vec_a_i[l] > vec_b_i[l]) ? 8'sd1 : 8'sd0; // compare
          5'd6: vec_o[l] <= (vec_a_i[l] > 0) ? vec_a_i[l] : '0; // relu
          5'd7: vec_o[l] <= (x >= 0) ? (8'sd64 - (x >>> 2)) : (8'sd64 + ((-x) >>> 2)); // sigmoid approx
          5'd8: vec_o[l] <= (x >= 0) ? ((8'sd64 * x) / (8'sd64 + x)) : -((8'sd64 * (-x)) / (8'sd64 + (-x))); // tanh approx
          5'd9: vec_o[l] <= 8'sd16 + x + ((x * x) >>> 4); // exp approx
          5'd10: vec_o[l] <= (x > 0) ? (8'sd8 + (x >>> 2)) : 8'sd0; // log approx
          default: vec_o[l] <= (x > 0) ? ((x >>> 1) + 8'sd1) : 8'sd0; // sqrt approx
        endcase
      end
    end
  end
endmodule
