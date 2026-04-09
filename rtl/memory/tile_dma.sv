module tile_dma #(
  parameter int ADDR_W = 32,
  parameter int LEN_W  = 16
) (
  input  logic              clk_i,
  input  logic              rst_ni,
  input  logic              start_i,
  input  logic [ADDR_W-1:0] base_addr_i,
  input  logic [15:0]       rows_i,
  input  logic [15:0]       cols_i,
  input  logic [15:0]       stride_i,
  output logic              busy_o,
  output logic              req_valid_o,
  output logic [ADDR_W-1:0] req_addr_o,
  output logic [LEN_W-1:0]  req_len_o,
  input  logic              req_ready_i,
  input  logic              done_i
);
  typedef enum logic [1:0] {IDLE, ISSUE, WAIT_DONE} state_e;
  state_e state_q, state_d;

  logic [15:0] row_q, row_d;
  logic [ADDR_W-1:0] addr_q, addr_d;

  always_comb begin
    state_d = state_q;
    row_d = row_q;
    addr_d = addr_q;

    req_valid_o = 1'b0;
    req_addr_o = addr_q;
    req_len_o = LEN_W'(cols_i);
    busy_o = (state_q != IDLE);

    case (state_q)
      IDLE: begin
        if (start_i) begin
          row_d = '0;
          addr_d = base_addr_i;
          state_d = ISSUE;
        end
      end
      ISSUE: begin
        req_valid_o = 1'b1;
        req_addr_o = addr_q;
        if (req_valid_o && req_ready_i) begin
          if (row_q == rows_i - 1) begin
            state_d = WAIT_DONE;
          end else begin
            row_d = row_q + 1'b1;
            addr_d = addr_q + ADDR_W'(stride_i);
          end
        end
      end
      WAIT_DONE: begin
        if (done_i) begin
          state_d = IDLE;
        end
      end
      default: state_d = IDLE;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= IDLE;
      row_q <= '0;
      addr_q <= '0;
    end else begin
      state_q <= state_d;
      row_q <= row_d;
      addr_q <= addr_d;
    end
  end
endmodule
