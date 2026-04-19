module precision_convert_unit (
  input  logic               valid_i,
  input  logic [1:0]         mode_i, // 0=int16->int8,1=scale,2=clip
  input  logic signed [15:0] data_i,
  input  logic signed [7:0]  scale_i,
  output logic               valid_o,
  output logic signed [15:0] out_o
);
  logic signed [15:0] scaled;
  always_comb begin
    scaled = (data_i * scale_i) >>> 4;
    valid_o = valid_i;
    unique case (mode_i)
      2'd0: out_o = (data_i > 127) ? 16'sd127 : ((data_i < -128) ? -16'sd128 : data_i);
      2'd1: out_o = scaled;
      default: out_o = (scaled > 1024) ? 16'sd1024 : ((scaled < -1024) ? -16'sd1024 : scaled);
    endcase
  end
endmodule
