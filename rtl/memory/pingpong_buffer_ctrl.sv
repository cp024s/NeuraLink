module pingpong_buffer_ctrl (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic load_done_i,
  input  logic compute_done_i,
  output logic rd_bank_o,
  output logic wr_bank_o,
  output logic can_compute_o
);
  logic rd_bank_q, wr_bank_q;
  logic data_ready_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_bank_q <= 1'b0;
      wr_bank_q <= 1'b1;
      data_ready_q <= 1'b0;
    end else begin
      if (load_done_i) begin
        rd_bank_q <= wr_bank_q;
        wr_bank_q <= ~wr_bank_q;
        data_ready_q <= 1'b1;
      end
      if (compute_done_i) begin
        data_ready_q <= 1'b0;
      end
    end
  end

  assign rd_bank_o = rd_bank_q;
  assign wr_bank_o = wr_bank_q;
  assign can_compute_o = data_ready_q;
endmodule
