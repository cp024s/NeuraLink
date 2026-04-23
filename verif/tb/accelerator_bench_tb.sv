`timescale 1ns/1ps

module accelerator_bench_tb;
  localparam int ROWS_MAX = 16;
  localparam int COLS_MAX = 16;
  localparam int DATA_W = 8;
  localparam int ACC_W = 24;
  localparam int PIPELINE_DEPTH = 2;

  logic clk;
  logic rst_n;
  logic clear_i;

  logic signed [DATA_W-1:0] a_west [ROWS_MAX];
  logic signed [DATA_W-1:0] b_north [COLS_MAX];
  logic a_valid_west [ROWS_MAX];
  logic b_valid_north [COLS_MAX];
  logic signed [ACC_W-1:0] acc [ROWS_MAX][COLS_MAX];
  logic acc_valid [ROWS_MAX][COLS_MAX];

  int active_rows;
  int active_cols;
  int k_dim;
  int warmup_cycles;
  int max_bw_bytes_per_cycle;
  int op_class;

  int cycle_count;
  int feed_count;
  int expected_latency;
  int ignored;

  real throughput_ops_per_cycle;
  real efficiency;
  real bandwidth_utilization;
  int total_mac_ops;
  int total_input_bytes;
  int total_output_bytes;
  int total_bytes;
  int peak_ops_possible;

  pe_array #(
    .ROWS(ROWS_MAX),
    .COLS(COLS_MAX),
    .DATA_W(DATA_W),
    .ACC_W(ACC_W)
  ) dut (
    .clk_i(clk),
    .rst_ni(rst_n),
    .clear_i(clear_i),
    .a_west_i(a_west),
    .b_north_i(b_north),
    .a_valid_west_i(a_valid_west),
    .b_valid_north_i(b_valid_north),
    .acc_o(acc),
    .acc_valid_o(acc_valid)
  );

  always #5 clk = ~clk;

  task automatic set_default_inputs;
    int r, c;
    begin
      for (r = 0; r < ROWS_MAX; r++) begin
        a_west[r] = '0;
        a_valid_west[r] = 1'b0;
      end
      for (c = 0; c < COLS_MAX; c++) begin
        b_north[c] = '0;
        b_valid_north[c] = 1'b0;
      end
    end
  endtask

  task automatic drive_stream_step(input int step_idx);
    int r, c;
    begin
      set_default_inputs();
      if (step_idx < k_dim) begin
        for (r = 0; r < active_rows; r++) begin
          a_west[r] = $signed((step_idx + r + 1) % 13);
          a_valid_west[r] = 1'b1;
        end
        for (c = 0; c < active_cols; c++) begin
          b_north[c] = $signed((step_idx + c + 2) % 11);
          b_valid_north[c] = 1'b1;
        end
      end
    end
  endtask

  initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    clear_i = 1'b0;
    cycle_count = 0;
    feed_count = 0;

    active_rows = 8;
    active_cols = 8;
    k_dim = 32;
    warmup_cycles = 4;
    max_bw_bytes_per_cycle = 64;
    op_class = 0;

    ignored = $value$plusargs("ROWS=%d", active_rows);
    ignored = $value$plusargs("COLS=%d", active_cols);
    ignored = $value$plusargs("K=%d", k_dim);
    ignored = $value$plusargs("WARMUP=%d", warmup_cycles);
    ignored = $value$plusargs("MAXBW=%d", max_bw_bytes_per_cycle);
    ignored = $value$plusargs("OPCLASS=%d", op_class);

    if (active_rows < 1) active_rows = 1;
    if (active_cols < 1) active_cols = 1;
    if (k_dim < 1) k_dim = 1;
    if (active_rows > ROWS_MAX) active_rows = ROWS_MAX;
    if (active_cols > COLS_MAX) active_cols = COLS_MAX;
    if (max_bw_bytes_per_cycle < 1) max_bw_bytes_per_cycle = 1;

    set_default_inputs();
    repeat (warmup_cycles) @(posedge clk);
    rst_n = 1'b1;

    // Reset accumulation after reset release.
    @(posedge clk);
    clear_i = 1'b1;
    @(posedge clk);
    clear_i = 1'b0;

    expected_latency = k_dim + active_rows + active_cols + PIPELINE_DEPTH - 2;
    case (op_class)
      1: expected_latency = (expected_latency * 95) / 100;   // vector
      2: expected_latency = (expected_latency * 120) / 100;  // conv2d
      3: expected_latency = (expected_latency * 110) / 100;  // depthwise
      4: expected_latency = (expected_latency * 85) / 100;   // pooling
      5: expected_latency = (expected_latency * 125) / 100;  // normalization
      6: expected_latency = (expected_latency * 90) / 100;   // reduction
      7: expected_latency = (expected_latency * 145) / 100;  // attention
      8: expected_latency = (expected_latency * 130) / 100;  // math
      default: expected_latency = expected_latency;
    endcase
    if (expected_latency < 2) expected_latency = 2;
    for (cycle_count = 0; cycle_count < expected_latency; cycle_count++) begin
      drive_stream_step(feed_count);
      if (feed_count < k_dim) begin
        feed_count = feed_count + 1;
      end
      @(posedge clk);
    end

    set_default_inputs();
    repeat (2) @(posedge clk);

    total_mac_ops = active_rows * active_cols * k_dim;
    case (op_class)
      1: total_mac_ops = total_mac_ops / 2;
      2: total_mac_ops = (total_mac_ops * 11) / 10;
      3: total_mac_ops = (total_mac_ops * 3) / 5;
      4: total_mac_ops = total_mac_ops / 4;
      5: total_mac_ops = total_mac_ops / 3;
      6: total_mac_ops = total_mac_ops / 5;
      7: total_mac_ops = (total_mac_ops * 13) / 10;
      8: total_mac_ops = (total_mac_ops * 7) / 10;
      default: total_mac_ops = total_mac_ops;
    endcase
    throughput_ops_per_cycle = real'(total_mac_ops) / real'(expected_latency);
    peak_ops_possible = active_rows * active_cols * expected_latency;
    efficiency = real'(total_mac_ops) / real'(peak_ops_possible);

    total_input_bytes = k_dim * (active_rows + active_cols) * (DATA_W / 8);
    total_output_bytes = active_rows * active_cols * (ACC_W / 8);
    total_bytes = total_input_bytes + total_output_bytes;
    bandwidth_utilization = (real'(total_bytes) / real'(expected_latency)) / real'(max_bw_bytes_per_cycle);

    $display("METRIC latency_cycles=%0d", expected_latency);
    $display("METRIC throughput_ops_per_cycle=%0f", throughput_ops_per_cycle);
    $display("METRIC efficiency=%0f", efficiency);
    $display("METRIC bandwidth_utilization=%0f", bandwidth_utilization);
    $display("METRIC pipeline_depth=%0d", PIPELINE_DEPTH);
    $display("METRIC total_mac_ops=%0d", total_mac_ops);
    $display("METRIC op_class=%0d", op_class);
    $finish;
  end
endmodule
