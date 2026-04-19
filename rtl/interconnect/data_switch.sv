module data_switch #(
  parameter int DATA_W = 8
) (
  input  logic                     select_vpu_i,
  input  logic                     mmu_valid_i,
  input  logic signed [DATA_W-1:0] mmu_data_i,
  input  logic                     vpu_valid_i,
  input  logic signed [DATA_W-1:0] vpu_data_i,
  output logic                     out_valid_o,
  output logic signed [DATA_W-1:0] out_data_o
);
  always_comb begin
    out_valid_o = 1'b0;
    out_data_o = '0;
    if (select_vpu_i) begin
      out_valid_o = vpu_valid_i;
      out_data_o = vpu_data_i;
    end else if (mmu_valid_i) begin
      out_valid_o = 1'b1;
      out_data_o = mmu_data_i;
    end else if (vpu_valid_i) begin
      out_valid_o = 1'b1;
      out_data_o = vpu_data_i;
    end
  end
endmodule
