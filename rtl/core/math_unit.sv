module math_unit #(
  parameter int DATA_W = 16
) (
  input  logic                      valid_i,
  input  logic [1:0]                mode_i, // 0=exp,1=log,2=sqrt
  input  logic signed [DATA_W-1:0]  data_i,
  output logic                      valid_o,
  output logic signed [DATA_W-1:0]  out_o
);
  logic signed [DATA_W-1:0] dabs;
  always_comb begin
    dabs = (data_i < 0) ? -data_i : data_i;
    valid_o = valid_i;
    unique case (mode_i)
      2'd0: out_o = 16'sd64 + data_i + ((data_i * data_i) >>> 5); // exp approx
      2'd1: out_o = (dabs > 0) ? (16'sd8 + (dabs >>> 3)) : 16'sd0; // log approx
      default: out_o = (dabs >>> 1) + 16'sd1; // sqrt approx
    endcase
  end
endmodule
