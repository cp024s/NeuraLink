module backpressure_controller #(
  parameter int CREDIT_W = 8
) (
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  logic                 enqueue_i,
  input  logic                 dequeue_i,
  input  logic [CREDIT_W-1:0]  max_credit_i,
  output logic                 stall_o,
  output logic [CREDIT_W-1:0]  credit_used_o
);
  logic [CREDIT_W-1:0] credit_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      credit_q <= '0;
    end else begin
      unique case ({enqueue_i, dequeue_i})
        2'b10: if (credit_q < max_credit_i) credit_q <= credit_q + 1'b1;
        2'b01: if (credit_q != 0) credit_q <= credit_q - 1'b1;
        default: credit_q <= credit_q;
      endcase
    end
  end

  assign stall_o = (credit_q >= max_credit_i);
  assign credit_used_o = credit_q;
endmodule
