module bank_addr_mapper #(
  parameter int ADDR_W = 32,
  parameter int NUM_BANKS = 4
) (
  input  logic [ADDR_W-1:0] addr_i,
  input  logic [$clog2(NUM_BANKS)-1:0] bank_skew_i,
  output logic [$clog2(NUM_BANKS)-1:0] bank_sel_o,
  output logic [ADDR_W-1:0] bank_addr_o
);
  localparam int BANK_BITS = (NUM_BANKS <= 1) ? 1 : $clog2(NUM_BANKS);

  logic [ADDR_W-1:0] word_addr;
  logic [BANK_BITS-1:0] bank_idx;

  assign word_addr = addr_i >> 2;
  assign bank_idx = word_addr[BANK_BITS-1:0] + bank_skew_i;
  assign bank_sel_o = bank_idx;
  assign bank_addr_o = {word_addr[ADDR_W-1:BANK_BITS], {BANK_BITS{1'b0}}, 2'b00};
endmodule
