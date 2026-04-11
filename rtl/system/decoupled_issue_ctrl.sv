module decoupled_issue_ctrl (
  input  logic clk_i,
  input  logic rst_ni,
  input  logic sched_valid_i,
  input  logic load_done_i,
  input  logic compute_done_i,
  input  logic store_done_i,
  input  logic can_compute_i,
  output logic sched_pop_o,
  output logic load_start_o,
  output logic compute_start_o,
  output logic store_start_o,
  output logic busy_o,
  output logic done_pulse_o
);
  typedef enum logic [2:0] {
    ISSUE_IDLE,
    ISSUE_LOAD,
    ISSUE_WAIT_COMPUTE,
    ISSUE_COMPUTE,
    ISSUE_STORE
  } issue_state_e;

  issue_state_e state_q, state_d;

  always_comb begin
    state_d = state_q;
    sched_pop_o = 1'b0;
    load_start_o = 1'b0;
    compute_start_o = 1'b0;
    store_start_o = 1'b0;
    done_pulse_o = 1'b0;

    unique case (state_q)
      ISSUE_IDLE: begin
        if (sched_valid_i) begin
          sched_pop_o = 1'b1;
          load_start_o = 1'b1;
          state_d = ISSUE_LOAD;
        end
      end
      ISSUE_LOAD: begin
        if (load_done_i) begin
          state_d = ISSUE_WAIT_COMPUTE;
        end
      end
      ISSUE_WAIT_COMPUTE: begin
        if (can_compute_i) begin
          compute_start_o = 1'b1;
          state_d = ISSUE_COMPUTE;
        end
      end
      ISSUE_COMPUTE: begin
        if (compute_done_i) begin
          store_start_o = 1'b1;
          state_d = ISSUE_STORE;
        end
      end
      ISSUE_STORE: begin
        if (store_done_i) begin
          done_pulse_o = 1'b1;
          state_d = ISSUE_IDLE;
        end
      end
      default: state_d = ISSUE_IDLE;
    endcase
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q <= ISSUE_IDLE;
    end else begin
      state_q <= state_d;
    end
  end

  assign busy_o = (state_q != ISSUE_IDLE);
endmodule
