module block_sparse_attention_scheduler #(
  parameter int MAX_BLOCKS = 64,
  parameter int IDX_W = 8
) (
  input  logic                clk_i,
  input  logic                rst_ni,
  input  logic                start_i,
  input  logic [MAX_BLOCKS-1:0] block_mask_i,
  input  logic                next_i,
  output logic                valid_o,
  output logic [IDX_W-1:0]    block_idx_o,
  output logic                done_o
);
  logic [MAX_BLOCKS-1:0] pending_q;
  logic active_q;
  logic [IDX_W-1:0] idx_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pending_q <= '0;
      active_q <= 1'b0;
      idx_q <= '0;
    end else begin
      if (start_i) begin
        pending_q <= block_mask_i;
        active_q <= 1'b1;
        idx_q <= '0;
      end else if (active_q && next_i && valid_o) begin
        pending_q[idx_q] <= 1'b0;
      end

      if (active_q && next_i) begin
        idx_q <= idx_q + 1'b1;
      end
      if (active_q && (pending_q == '0)) begin
        active_q <= 1'b0;
      end
    end
  end

  assign valid_o = active_q && pending_q[idx_q];
  assign block_idx_o = idx_q;
  assign done_o = !active_q;
endmodule
