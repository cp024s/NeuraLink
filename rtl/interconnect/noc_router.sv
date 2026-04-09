module noc_router #(
  parameter int FLIT_W = 64
) (
  input  logic              clk_i,
  input  logic              rst_ni,
  input  logic              in_valid_i,
  input  logic [FLIT_W-1:0] in_flit_i,
  output logic              in_ready_o,
  output logic              out_valid_o,
  output logic [FLIT_W-1:0] out_flit_o,
  input  logic              out_ready_i
);
  logic hold_valid_q;
  logic [FLIT_W-1:0] hold_flit_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      hold_valid_q <= 1'b0;
      hold_flit_q <= '0;
    end else begin
      if (in_valid_i && in_ready_o) begin
        hold_flit_q <= in_flit_i;
        hold_valid_q <= 1'b1;
      end else if (out_valid_o && out_ready_i) begin
        hold_valid_q <= 1'b0;
      end
    end
  end

  assign in_ready_o = ~hold_valid_q;
  assign out_valid_o = hold_valid_q;
  assign out_flit_o = hold_flit_q;
endmodule
