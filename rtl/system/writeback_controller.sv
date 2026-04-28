module writeback_controller (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic start_i,
  input  logic fifo_empty_i,
  output logic fifo_pop_o,
  input  logic dma_store_done_i,
  output logic busy_o,
  output logic done_pulse_o
);
  typedef enum logic [1:0] {
    WB_IDLE,
    WB_DRAIN
  } wb_state_e;

  wb_state_e state_q, state_d;
  logic dma_done_seen_q, dma_done_seen_d;

  always_comb begin
    state_d = state_q;
    dma_done_seen_d = dma_done_seen_q;
    fifo_pop_o = 1'b0;
    done_pulse_o = 1'b0;

    unique case (state_q)
      WB_IDLE: begin
        if (start_i) begin
          dma_done_seen_d = 1'b0;
          state_d = WB_DRAIN;
        end
      end
      WB_DRAIN: begin
        if (!fifo_empty_i) begin
          fifo_pop_o = 1'b1;
        end
        if (dma_store_done_i) begin
          dma_done_seen_d = 1'b1;
        end
        if (dma_done_seen_d && fifo_empty_i) begin
          done_pulse_o = 1'b1;
          state_d = WB_IDLE;
        end
      end
      default: state_d = WB_IDLE;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= WB_IDLE;
      dma_done_seen_q <= 1'b0;
    end else begin
      state_q <= state_d;
      dma_done_seen_q <= dma_done_seen_d;
    end
  end

  assign busy_o = (state_q != WB_IDLE);
endmodule

