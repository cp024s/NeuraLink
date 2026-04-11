`include "accel_pkg.sv"

module edge_tpu_top #(
  parameter int ROWS = 4,
  parameter int COLS = 4,
  parameter int DATA_W = accel_pkg::DATA_W,
  parameter int ACC_W = accel_pkg::ACC_W,
  parameter int NUM_MEM_BANKS = 4
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

  logic issue_load_start, issue_store_start, issue_busy, issue_done_pulse;
  logic load_done_pulse, store_done_pulse;
  logic scratch_can_compute, scratch_rd_bank, scratch_wr_bank;

  logic load_dma_busy, load_dma_req_valid, load_dma_req_ready, load_dma_done;
  logic [31:0] load_dma_req_addr;
  logic [15:0] load_dma_req_len;
  logic [15:0] load_done_count_q;

  logic store_dma_busy, store_dma_req_valid, store_dma_req_ready, store_dma_done;
  logic [31:0] store_dma_req_addr;
  logic [15:0] store_dma_req_len;
  logic [15:0] store_done_count_q;

  logic dma_req_valid, dma_req_ready;
  logic [31:0] dma_req_addr;
  logic [15:0] dma_req_len;
  logic [31:0] dma_req_addr_mapped;
  logic [$clog2(NUM_MEM_BANKS)-1:0] dma_req_bank_sel;

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

  decoupled_issue_ctrl u_decoupled_issue_ctrl (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .sched_valid_i(sched_valid),
    .load_done_i(load_done_pulse),
    .compute_done_i(seq_done),
    .store_done_i(store_done_pulse),
    .can_compute_i(scratch_can_compute),
    .sched_pop_o(sched_pop),
    .load_start_o(issue_load_start),
    .compute_start_o(seq_start),
    .store_start_o(issue_store_start),
    .busy_o(issue_busy),
    .done_pulse_o(issue_done_pulse)
  );

  pingpong_buffer_ctrl u_pingpong_buffer_ctrl (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .load_done_i(load_done_pulse),
    .compute_done_i(seq_done),
    .rd_bank_o(scratch_rd_bank),
    .wr_bank_o(scratch_wr_bank),
    .can_compute_o(scratch_can_compute)
  );

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      active_desc_q <= '0;
      active_desc_valid_q <= 1'b0;
      load_done_count_q <= '0;
      store_done_count_q <= '0;
      switch_event_count_q <= '0;
      result00_q <= '0;
    end else begin
      if (sched_pop) begin
        active_desc_q <= sched_desc;
        active_desc_valid_q <= 1'b1;
        load_done_count_q <= (sched_desc.m + sched_desc.n + 16'd2);
      end else if (load_dma_busy && (load_done_count_q != 0)) begin
        load_done_count_q <= load_done_count_q - 1'b1;
      end

      if (issue_store_start) begin
        store_done_count_q <= (active_desc_q.m + 16'd2);
      end else if (store_dma_busy && (store_done_count_q != 0)) begin
        store_done_count_q <= store_done_count_q - 1'b1;
      end

      if (issue_done_pulse) begin
        active_desc_valid_q <= 1'b0;
      end

      if (switch_valid) begin
        switch_event_count_q <= switch_event_count_q + 1'b1;
        result00_q <= {{(ACC_W-DATA_W){switch_data[DATA_W-1]}}, switch_data};
      end
    end
  end

  assign load_done_pulse = load_dma_busy && (load_done_count_q == 16'd1);
  assign load_dma_done = load_done_pulse;
  assign store_done_pulse = store_dma_busy && (store_done_count_q == 16'd1);
  assign store_dma_done = store_done_pulse;

  tile_dma u_tile_dma_load (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .start_i(issue_load_start),
    .base_addr_i(active_desc_q.a_base),
    .rows_i(active_desc_q.m),
    .cols_i(active_desc_q.k),
    .stride_i(active_desc_q.n),
    .busy_o(load_dma_busy),
    .req_valid_o(load_dma_req_valid),
    .req_addr_o(load_dma_req_addr),
    .req_len_o(load_dma_req_len),
    .req_ready_i(load_dma_req_ready),
    .done_i(load_dma_done)
  );

  tile_dma u_tile_dma_store (
    .clk_i(clk_i),
    .rst_ni(rst_ni),
    .start_i(issue_store_start),
    .base_addr_i(active_desc_q.c_base),
    .rows_i(active_desc_q.m),
    .cols_i(active_desc_q.n),
    .stride_i(active_desc_q.n),
    .busy_o(store_dma_busy),
    .req_valid_o(store_dma_req_valid),
    .req_addr_o(store_dma_req_addr),
    .req_len_o(store_dma_req_len),
    .req_ready_i(store_dma_req_ready),
    .done_i(store_dma_done)
  );

  // Priority arbiter: keep load traffic ahead of store traffic.
  always_comb begin
    dma_req_valid = load_dma_req_valid | store_dma_req_valid;
    dma_req_addr = load_dma_req_valid ? load_dma_req_addr : store_dma_req_addr;
    dma_req_len = load_dma_req_valid ? load_dma_req_len : store_dma_req_len;
  end
  assign dma_req_ready = 1'b1;
  assign load_dma_req_ready = 1'b1;
  assign store_dma_req_ready = 1'b1;

  bank_addr_mapper #(
    .ADDR_W(32),
    .NUM_BANKS(NUM_MEM_BANKS)
  ) u_bank_addr_mapper (
    .addr_i(dma_req_addr),
    .bank_skew_i({($clog2(NUM_MEM_BANKS)){scratch_wr_bank}}),
    .bank_sel_o(dma_req_bank_sel),
    .bank_addr_o(dma_req_addr_mapped)
  );

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

  assign noc_in_valid = dma_req_valid | switch_valid;
  assign noc_in_flit = dma_req_valid ?
    {14'h2aa, dma_req_bank_sel, dma_req_addr_mapped, dma_req_len} :
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

  assign busy_o = issue_busy | load_dma_busy | store_dma_busy | seq_busy | active_desc_valid_q;
  assign done_o = issue_done_pulse;
  assign pe_active_cycles_o = pe_active_cycles;
  assign pe_idle_cycles_o = pe_idle_cycles;
  assign dma_stall_cycles_o = dma_stall_cycles;
  assign noc_flit_count_o = noc_flit_count + switch_event_count_q;

`ifndef SYNTHESIS
  always_ff @(posedge clk_i) begin
    if (rst_ni) begin
      assert (!(issue_load_start && issue_store_start))
        else $error("load/store cannot start in same cycle");
    end
  end
`endif
endmodule
