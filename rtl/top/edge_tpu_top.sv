`include "accel_pkg.sv"

module edge_tpu_top #(
  parameter int ROWS = 4,
  parameter int COLS = 4
) (
  input logic clk_i,
  input logic rst_ni,
  input logic start_i,
  input accel_pkg::tile_desc_t tile_desc_i,
  output logic busy_o,
  output logic done_o,
  output logic signed [ACC_W-1:0] result00_o,
  output logic [31:0] pe_active_cycles_o,
  output logic [31:0] pe_idle_cycles_o,
  output logic [31:0] dma_stall_cycles_o,
  output logic [31:0] noc_flit_count_o
);
  import accel_pkg::*;

  logic clear_array, seq_start, seq_busy, seq_done;
  logic sched_valid, sched_full, sched_empty, sched_pop;
  tile_desc_t sched_desc;
  tile_desc_t active_desc_q;
  logic active_desc_valid_q;

  logic dma_busy, dma_start, dma_req_valid, dma_req_ready, dma_done;
  logic [31:0] dma_req_addr;
  logic [15:0] dma_req_len;
  logic [15:0] dma_done_count_q;

  logic signed [DATA_W-1:0] a_west [ROWS];
  logic signed [DATA_W-1:0] b_north [COLS];
  logic a_valid_west [ROWS];
  logic b_valid_north [COLS];
  logic signed [ACC_W-1:0] acc [ROWS][COLS];
  logic acc_valid [ROWS][COLS];
  logic [31:0] pe_active_cycles, pe_idle_cycles, dma_stall_cycles, noc_flit_count;
  logic pe_any_active;

  logic noc_in_valid, noc_in_ready, noc_out_valid, noc_out_ready;
  logic [63:0] noc_in_flit, noc_out_flit;
  logic signed [DATA_W-1:0] vpu_in_a [4], vpu_in_b [4], vpu_out [4];
  logic signed [DATA_W-1:0] op_vec4_a [4], op_vec4_b [4];
  logic signed [7:0] conv_win [9], conv_ker [9];
  logic signed [15:0] norm_vec [4], norm_out [4], pool_vec [4], red_vec [4];
  logic signed [DATA_W-1:0] act_data;
  logic vpu_valid, vpu_out_valid, act_valid, switch_valid, conv_valid, pool_valid, red_valid, norm_valid, math_valid, prec_valid;
  logic [4:0] vpu_op;
  logic signed [20:0] conv_out;
  logic signed [15:0] pool_out, red_out, math_out, prec_out;
  logic signed [DATA_W-1:0] switch_data;
  logic signed [DATA_W-1:0] op_data_mux;
  logic op_valid_mux;
  logic [31:0] switch_event_count_q;
  logic signed [ACC_W-1:0] result00_q;

  tile_scheduler #(
    .Q_DEPTH(16)
  ) u_tile_scheduler (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .push_i(start_i),
    .push_desc_i(tile_desc_i),
    .pop_i(sched_pop),
    .pop_desc_o(sched_desc),
    .valid_o(sched_valid),
    .full_o(sched_full),
    .empty_o(sched_empty)
  );

  always_comb begin
    sched_pop = 1'b0;
    dma_start = 1'b0;
    seq_start = 1'b0;
    dma_done = 1'b0;

    if (sched_valid && !active_desc_valid_q && !dma_busy && !seq_busy) begin
      sched_pop = 1'b1;
      dma_start = 1'b1;
    end

    // Simple DMA completion model for integration-level simulation.
    if (dma_busy && (dma_done_count_q == 16'd1)) begin
      dma_done = 1'b1;
      seq_start = 1'b1;
    end
  end

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      active_desc_q <= '0;
      active_desc_valid_q <= 1'b0;
      dma_done_count_q <= '0;
      switch_event_count_q <= '0;
      result00_q <= '0;
    end else begin
      if (sched_pop) begin
        active_desc_q <= sched_desc;
        active_desc_valid_q <= 1'b1;
        dma_done_count_q <= (sched_desc.m + sched_desc.n + 16'd2);
      end else if (dma_busy && (dma_done_count_q != 0)) begin
        dma_done_count_q <= dma_done_count_q - 1'b1;
      end

      if (seq_done) begin
        active_desc_valid_q <= 1'b0;
      end

      if (switch_valid) begin
        switch_event_count_q <= switch_event_count_q + 1'b1;
        result00_q <= {{(ACC_W-DATA_W){switch_data[DATA_W-1]}}, switch_data};
      end
    end
  end

  tile_dma u_tile_dma (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .start_i(dma_start),
    .base_addr_i(active_desc_q.a_base),
    .rows_i(active_desc_q.m),
    .cols_i(active_desc_q.n),
    .stride_i(active_desc_q.n),
    .busy_o(dma_busy),
    .req_valid_o(dma_req_valid),
    .req_addr_o(dma_req_addr),
    .req_len_o(dma_req_len),
    .req_ready_i(dma_req_ready),
    .done_i(dma_done)
  );
  assign dma_req_ready = 1'b1;

  instruction_sequencer #(
    .ROWS(ROWS),
    .COLS(COLS),
    .DATA_W(DATA_W)
  ) u_instruction_sequencer (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .start_i(seq_start),
    .m_i(active_desc_q.m),
    .n_i(active_desc_q.n),
    .k_i(active_desc_q.k),
    .clear_o(clear_array),
    .busy_o(seq_busy),
    .done_o(seq_done),
    .a_west_o(a_west),
    .b_north_o(b_north),
    .a_valid_west_o(a_valid_west),
    .b_valid_north_o(b_valid_north)
  );

  pe_array #(
    .ROWS(ROWS),
    .COLS(COLS),
    .DATA_W(DATA_W),
    .ACC_W(ACC_W)
  ) u_array (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .clear_i(clear_array),
    .a_west_i(a_west),
    .b_north_i(b_north),
    .a_valid_west_i(a_valid_west),
    .b_valid_north_i(b_valid_north),
    .acc_o(acc),
    .acc_valid_o(acc_valid)
  );

  assign pe_any_active = seq_busy;
  assign result00_o = result00_q;

  always_comb begin
    for (int l = 0; l < 4; l++) begin
      if (l < COLS) begin
        vpu_in_a[l] = acc[0][l][DATA_W-1:0];
        vpu_in_b[l] = $signed(l + 1);
        op_vec4_a[l] = $signed(active_desc_q.k[DATA_W-1:0] + l);
        op_vec4_b[l] = $signed(active_desc_q.m[DATA_W-1:0] + l);
        pool_vec[l] = {{8{1'b0}}, op_vec4_a[l]};
        red_vec[l] = {{8{1'b0}}, op_vec4_b[l]};
        norm_vec[l] = {{8{1'b0}}, op_vec4_a[l]};
      end else begin
        vpu_in_a[l] = '0;
        vpu_in_b[l] = '0;
        op_vec4_a[l] = '0;
        op_vec4_b[l] = '0;
        pool_vec[l] = '0;
        red_vec[l] = '0;
        norm_vec[l] = '0;
      end
    end
    for (int i = 0; i < 9; i++) begin
      conv_win[i] = $signed(active_desc_q.k[7:0] + i);
      conv_ker[i] = $signed(i + 1);
    end
  end
  assign vpu_valid = pe_any_active;
  assign vpu_op = (active_desc_q.op_class == OP_MATH) ? 5'd9 :
                  (active_desc_q.op_class == OP_REDUCTION) ? 5'd2 :
                  (active_desc_q.op_class == OP_ATTENTION) ? 5'd8 :
                  5'd0;

  vector_unit #(
    .LANES(4),
    .DATA_W(DATA_W)
  ) u_vector_unit (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .valid_i(vpu_valid),
    .op_i(vpu_op),
    .vec_a_i(vpu_in_a),
    .vec_b_i(vpu_in_b),
    .valid_o(vpu_out_valid),
    .vec_o(vpu_out)
  );

  conv2d_unit #(
    .DATA_W(8)
  ) u_conv2d_unit (
    .valid_i(seq_busy),
    .depthwise_i(active_desc_q.op_class == OP_DEPTHWISE),
    .win_i(conv_win),
    .ker_i(conv_ker),
    .valid_o(conv_valid),
    .out_o(conv_out)
  );

  pooling_unit #(
    .DATA_W(16)
  ) u_pooling_unit (
    .valid_i(seq_busy),
    .mode_i(2'd0),
    .vec_i(pool_vec),
    .valid_o(pool_valid),
    .out_o(pool_out)
  );

  reduction_unit #(
    .DATA_W(16)
  ) u_reduction_unit (
    .valid_i(seq_busy),
    .mode_i(3'd0),
    .vec_i(red_vec),
    .valid_o(red_valid),
    .out_o(red_out)
  );

  norm_unit #(
    .DATA_W(16)
  ) u_norm_unit (
    .valid_i(seq_busy),
    .mode_i(2'd0),
    .vec_i(norm_vec),
    .gamma_i(16'sd4),
    .beta_i(16'sd1),
    .valid_o(norm_valid),
    .out_o(norm_out)
  );

  math_unit #(
    .DATA_W(16)
  ) u_math_unit (
    .valid_i(seq_busy),
    .mode_i(2'd0),
    .data_i(norm_out[0]),
    .valid_o(math_valid),
    .out_o(math_out)
  );

  precision_convert_unit u_precision_convert_unit (
    .valid_i(math_valid),
    .mode_i(2'd0),
    .data_i(math_out),
    .scale_i(8'sd4),
    .valid_o(prec_valid),
    .out_o(prec_out)
  );

  activation_pipe #(
    .DATA_W(DATA_W)
  ) u_activation_pipe (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .valid_i(vpu_out_valid),
    .data_i(vpu_out[0]),
    .valid_o(act_valid),
    .data_o(act_data)
  );

  always_comb begin
    op_valid_mux = act_valid;
    op_data_mux = act_data;
    unique case (active_desc_q.op_class)
      OP_CONV2D, OP_DEPTHWISE: begin
        op_valid_mux = conv_valid;
        op_data_mux = conv_out[7:0];
      end
      OP_POOLING: begin
        op_valid_mux = pool_valid;
        op_data_mux = pool_out[7:0];
      end
      OP_NORM: begin
        op_valid_mux = norm_valid;
        op_data_mux = norm_out[0][7:0];
      end
      OP_REDUCTION: begin
        op_valid_mux = red_valid;
        op_data_mux = red_out[7:0];
      end
      OP_MATH, OP_ATTENTION: begin
        op_valid_mux = prec_valid;
        op_data_mux = prec_out[7:0];
      end
      default: begin
        op_valid_mux = act_valid;
        op_data_mux = act_data;
      end
    endcase
  end

  data_switch #(
    .DATA_W(DATA_W)
  ) u_data_switch (
    .select_vpu_i(active_desc_q.op_class != OP_GEMM),
    .mmu_valid_i(seq_busy),
    .mmu_data_i($signed(active_desc_q.k[DATA_W-1:0] + active_desc_q.op_class)),
    .vpu_valid_i(op_valid_mux),
    .vpu_data_i(op_data_mux),
    .out_valid_o(switch_valid),
    .out_data_o(switch_data)
  );

  // NoC and counters are integrated early so instrumentation is available
  // as architecture complexity increases.
  assign noc_in_valid = dma_req_valid | switch_valid;
  assign noc_in_flit = dma_req_valid ?
    {16'hd00d, dma_req_addr, dma_req_len} :
    {56'd0, switch_data};
  assign noc_out_ready = 1'b1;

  noc_router u_noc_router (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .in_valid_i(noc_in_valid),
    .in_flit_i(noc_in_flit),
    .in_ready_o(noc_in_ready),
    .out_valid_o(noc_out_valid),
    .out_flit_o(noc_out_flit),
    .out_ready_i(noc_out_ready)
  );

  perf_counter_block u_perf_counter_block (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .enable_i(1'b1),
    .pe_active_i(pe_any_active),
    .dma_stall_i(dma_req_valid & ~dma_req_ready),
    .noc_flits_i(noc_out_valid ? 16'd1 : 16'd0),
    .pe_active_cycles_o(pe_active_cycles),
    .pe_idle_cycles_o(pe_idle_cycles),
    .dma_stall_cycles_o(dma_stall_cycles),
    .noc_flit_count_o(noc_flit_count)
  );

  assign busy_o = active_desc_valid_q | dma_busy | seq_busy;
  assign done_o = seq_done;
  assign pe_active_cycles_o = pe_active_cycles;
  assign pe_idle_cycles_o = pe_idle_cycles;
  assign dma_stall_cycles_o = dma_stall_cycles;
  assign noc_flit_count_o = noc_flit_count + switch_event_count_q;
endmodule
