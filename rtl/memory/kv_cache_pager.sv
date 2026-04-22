module kv_cache_pager #(
  parameter int PAGE_COUNT = 256,
  parameter int PAGE_W = 12,
  parameter int TOKEN_W = 16
) (
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  logic                 alloc_i,
  input  logic [TOKEN_W-1:0]   token_idx_i,
  output logic                 alloc_ok_o,
  output logic [PAGE_W-1:0]    page_addr_o,
  input  logic                 free_i,
  input  logic [TOKEN_W-1:0]   free_token_idx_i
);
  logic [PAGE_W-1:0] page_table [0:PAGE_COUNT-1];
  logic [PAGE_COUNT-1:0] valid_q;
  logic [PAGE_W-1:0] alloc_ptr_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      valid_q <= '0;
      alloc_ptr_q <= '0;
    end else begin
      if (alloc_i && alloc_ok_o) begin
        page_table[token_idx_i] <= alloc_ptr_q;
        valid_q[token_idx_i] <= 1'b1;
        alloc_ptr_q <= alloc_ptr_q + 1'b1;
      end
      if (free_i) begin
        valid_q[free_token_idx_i] <= 1'b0;
      end
    end
  end

  assign alloc_ok_o = !valid_q[token_idx_i];
  assign page_addr_o = alloc_ok_o ? alloc_ptr_q : page_table[token_idx_i];
endmodule
