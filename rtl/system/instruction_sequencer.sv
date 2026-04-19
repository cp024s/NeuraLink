module instruction_sequencer #(
  parameter int ROWS = 4,
  parameter int COLS = 4,
  parameter int DATA_W = 8
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     start_i,
  input  logic [15:0]              m_i,
  input  logic [15:0]              n_i,
  input  logic [15:0]              k_i,
  output logic                     clear_o,
  output logic                     busy_o,
  output logic                     done_o,
  output logic signed [DATA_W-1:0] a_west_o [ROWS],
  output logic signed [DATA_W-1:0] b_north_o [COLS],
  output logic                     a_valid_west_o [ROWS],
  output logic                     b_valid_north_o [COLS]
);
  typedef enum logic [1:0] {SEQ_IDLE, SEQ_CLEAR, SEQ_STREAM, SEQ_DRAIN} seq_state_e;
  seq_state_e state_q, state_d;

  logic [15:0] m_q, n_q, k_q;
  logic [15:0] k_count_q, k_count_d;
  logic [15:0] drain_count_q, drain_count_d;

  logic [15:0] m_eff, n_eff, k_eff;

  assign m_eff = (m_q > ROWS) ? ROWS : m_q;
  assign n_eff = (n_q > COLS) ? COLS : n_q;
  assign k_eff = (k_q == 0) ? 16'd1 : k_q;

  always_comb begin
    state_d = state_q;
    k_count_d = k_count_q;
    drain_count_d = drain_count_q;
    clear_o = 1'b0;
    done_o = 1'b0;

    for (int r = 0; r < ROWS; r++) begin
      a_west_o[r] = '0;
      a_valid_west_o[r] = 1'b0;
    end
    for (int c = 0; c < COLS; c++) begin
      b_north_o[c] = '0;
      b_valid_north_o[c] = 1'b0;
    end

    case (state_q)
      SEQ_IDLE: begin
        if (start_i) begin
          state_d = SEQ_CLEAR;
        end
      end
      SEQ_CLEAR: begin
        clear_o = 1'b1;
        k_count_d = '0;
        drain_count_d = m_eff + n_eff;
        state_d = SEQ_STREAM;
      end
      SEQ_STREAM: begin
        for (int r = 0; r < ROWS; r++) begin
          if (r < m_eff) begin
            a_west_o[r] = $signed((k_count_q + r + 1) % 13);
            a_valid_west_o[r] = 1'b1;
          end
        end
        for (int c = 0; c < COLS; c++) begin
          if (c < n_eff) begin
            b_north_o[c] = $signed((k_count_q + c + 2) % 11);
            b_valid_north_o[c] = 1'b1;
          end
        end
        if (k_count_q == k_eff - 1) begin
          state_d = SEQ_DRAIN;
        end else begin
          k_count_d = k_count_q + 1'b1;
        end
      end
      SEQ_DRAIN: begin
        if (drain_count_q == 0) begin
          done_o = 1'b1;
          state_d = SEQ_IDLE;
        end else begin
          drain_count_d = drain_count_q - 1'b1;
        end
      end
      default: state_d = SEQ_IDLE;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= SEQ_IDLE;
      k_count_q <= '0;
      drain_count_q <= '0;
      m_q <= '0;
      n_q <= '0;
      k_q <= '0;
    end else begin
      state_q <= state_d;
      k_count_q <= k_count_d;
      drain_count_q <= drain_count_d;
      if (start_i && state_q == SEQ_IDLE) begin
        m_q <= m_i;
        n_q <= n_i;
        k_q <= k_i;
      end
    end
  end

  assign busy_o = (state_q != SEQ_IDLE);
endmodule
