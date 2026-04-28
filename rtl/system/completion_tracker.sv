module completion_tracker (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        alloc_i,
  input  logic        compute_done_i,
  input  logic        writeback_done_i,
  output logic        inflight_o,
  output logic        retire_pulse_o,
  output logic [31:0] retired_count_o
);
  logic inflight_q;
  logic compute_done_q;
  logic writeback_done_q;
  logic [31:0] retired_count_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      inflight_q <= 1'b0;
      compute_done_q <= 1'b0;
      writeback_done_q <= 1'b0;
      retired_count_q <= '0;
      retire_pulse_o <= 1'b0;
    end else begin
      retire_pulse_o <= 1'b0;

      if (alloc_i) begin
        inflight_q <= 1'b1;
        compute_done_q <= 1'b0;
        writeback_done_q <= 1'b0;
      end

      if (inflight_q && compute_done_i) begin
        compute_done_q <= 1'b1;
      end

      if (inflight_q && writeback_done_i) begin
        writeback_done_q <= 1'b1;
      end

      if (inflight_q && (compute_done_q || compute_done_i) && (writeback_done_q || writeback_done_i)) begin
        inflight_q <= 1'b0;
        compute_done_q <= 1'b0;
        writeback_done_q <= 1'b0;
        retired_count_q <= retired_count_q + 1'b1;
        retire_pulse_o <= 1'b1;
      end
    end
  end

  assign inflight_o = inflight_q;
  assign retired_count_o = retired_count_q;
endmodule

