module pe_array_sva #(
  parameter int ROWS = 4,
  parameter int COLS = 4
) (
  input logic clk_i,
  input logic rst_ni,
  input logic acc_valid_i [ROWS][COLS]
);
  genvar r, c;
  generate
    for (r = 0; r < ROWS; r++) begin : g_r
      for (c = 0; c < COLS; c++) begin : g_c
        // Basic safety assertion: no X/Z when valid is asserted.
        property p_no_unknown_valid;
          @(posedge clk_i) disable iff (!rst_ni)
            acc_valid_i[r][c] |-> !$isunknown(acc_valid_i[r][c]);
        endproperty
        a_no_unknown_valid: assert property (p_no_unknown_valid);
      end
    end
  endgenerate
endmodule
