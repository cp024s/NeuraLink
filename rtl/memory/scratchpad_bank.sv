module scratchpad_bank #(
  parameter int DATA_W = 32,
  parameter int DEPTH  = 1024
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     wr_en_i,
  input  logic [$clog2(DEPTH)-1:0] wr_addr_i,
  input  logic [DATA_W-1:0]        wr_data_i,
  input  logic                     rd_en_i,
  input  logic [$clog2(DEPTH)-1:0] rd_addr_i,
  output logic [DATA_W-1:0]        rd_data_o
);
  logic [DATA_W-1:0] mem [0:DEPTH-1];

  always_ff @(posedge clk_i) begin
    if (wr_en_i) begin
      mem[wr_addr_i] <= wr_data_i;
    end
    if (rd_en_i) begin
      rd_data_o <= mem[rd_addr_i];
    end
  end
endmodule
