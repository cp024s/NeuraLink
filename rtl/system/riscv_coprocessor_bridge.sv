`include "accel_pkg.sv"

module riscv_coprocessor_bridge (
  input  logic                  clk_i,
  input  logic                  rst_ni,
  input  logic                  mmio_valid_i,
  input  logic                  mmio_we_i,
  input  logic [7:0]            mmio_addr_i,
  input  logic [31:0]           mmio_wdata_i,
  output logic [31:0]           mmio_rdata_o,
  output logic                  mmio_ready_o,
  output logic                  irq_o,
  output logic                  accel_start_o,
  output accel_pkg::tile_desc_t accel_desc_o,
  input  logic                  accel_busy_i,
  input  logic                  accel_done_i,
  input  logic [31:0]           perf_active_cycles_i,
  input  logic [31:0]           perf_idle_cycles_i,
  input  logic [31:0]           perf_dma_stall_cycles_i,
  input  logic [31:0]           perf_noc_flits_i
);
  import accel_pkg::*;

  localparam logic [7:0] REG_CTRL      = 8'h00;
  localparam logic [7:0] REG_STATUS    = 8'h04;
  localparam logic [7:0] REG_MNK       = 8'h08;
  localparam logic [7:0] REG_A_BASE    = 8'h0c;
  localparam logic [7:0] REG_B_BASE    = 8'h10;
  localparam logic [7:0] REG_C_BASE    = 8'h14;
  localparam logic [7:0] REG_MODE      = 8'h18;
  localparam logic [7:0] REG_OPCLASS   = 8'h1c;
  localparam logic [7:0] REG_PERF_ACT  = 8'h20;
  localparam logic [7:0] REG_PERF_IDLE = 8'h24;
  localparam logic [7:0] REG_PERF_DMA  = 8'h28;
  localparam logic [7:0] REG_PERF_NOC  = 8'h2c;
  localparam logic [7:0] REG_STRIDE_A  = 8'h30;
  localparam logic [7:0] REG_STRIDE_B  = 8'h34;
  localparam logic [7:0] REG_STRIDE_C  = 8'h38;
  localparam logic [7:0] REG_PRECFLOW  = 8'h3c;

  logic start_pending_q;
  logic irq_en_q;
  logic done_seen_q;

  tile_desc_t desc_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      desc_q <= '0;
      start_pending_q <= 1'b0;
      irq_en_q <= 1'b0;
      done_seen_q <= 1'b0;
    end else begin
      if (accel_done_i) begin
        done_seen_q <= 1'b1;
      end

      if (mmio_valid_i && mmio_we_i) begin
        unique case (mmio_addr_i)
          REG_CTRL: begin
            // bit0=start, bit1=irq_enable, bit2=clear_done
            if (mmio_wdata_i[0]) start_pending_q <= 1'b1;
            irq_en_q <= mmio_wdata_i[1];
            if (mmio_wdata_i[2]) done_seen_q <= 1'b0;
          end
          REG_MNK: begin
            desc_q.m <= mmio_wdata_i[31:16];
            desc_q.n <= mmio_wdata_i[15:0];
          end
          REG_A_BASE: desc_q.a_base <= mmio_wdata_i;
          REG_B_BASE: desc_q.b_base <= mmio_wdata_i;
          REG_C_BASE: desc_q.c_base <= mmio_wdata_i;
          REG_STRIDE_A: desc_q.stride_a <= mmio_wdata_i[15:0];
          REG_STRIDE_B: desc_q.stride_b <= mmio_wdata_i[15:0];
          REG_STRIDE_C: desc_q.stride_c <= mmio_wdata_i[15:0];
          REG_MODE: begin
            desc_q.mode <= mmio_wdata_i[1:0];
            desc_q.k <= mmio_wdata_i[31:16];
          end
          REG_OPCLASS: begin
            desc_q.op_class <= mmio_wdata_i[3:0];
            desc_q.sparse_en <= mmio_wdata_i[8];
          end
          REG_PRECFLOW: begin
            desc_q.precision <= mmio_wdata_i[1:0];
            desc_q.dep_flags <= mmio_wdata_i[7:4];
          end
          default: begin
          end
        endcase
      end

      if (start_pending_q && !accel_busy_i) begin
        start_pending_q <= 1'b0;
        done_seen_q <= 1'b0;
      end
    end
  end

  always_comb begin
    mmio_rdata_o = 32'd0;
    unique case (mmio_addr_i)
      REG_CTRL:      mmio_rdata_o = {29'd0, done_seen_q, irq_en_q, start_pending_q};
      REG_STATUS:    mmio_rdata_o = {30'd0, accel_busy_i, done_seen_q};
      REG_MNK:       mmio_rdata_o = {desc_q.m, desc_q.n};
      REG_A_BASE:    mmio_rdata_o = desc_q.a_base;
      REG_B_BASE:    mmio_rdata_o = desc_q.b_base;
      REG_C_BASE:    mmio_rdata_o = desc_q.c_base;
      REG_STRIDE_A:  mmio_rdata_o = {16'd0, desc_q.stride_a};
      REG_STRIDE_B:  mmio_rdata_o = {16'd0, desc_q.stride_b};
      REG_STRIDE_C:  mmio_rdata_o = {16'd0, desc_q.stride_c};
      REG_MODE:      mmio_rdata_o = {desc_q.k, 14'd0, desc_q.mode};
      REG_OPCLASS:   mmio_rdata_o = {23'd0, desc_q.sparse_en, 4'd0, desc_q.op_class};
      REG_PRECFLOW:  mmio_rdata_o = {24'd0, desc_q.dep_flags, 2'd0, desc_q.precision};
      REG_PERF_ACT:  mmio_rdata_o = perf_active_cycles_i;
      REG_PERF_IDLE: mmio_rdata_o = perf_idle_cycles_i;
      REG_PERF_DMA:  mmio_rdata_o = perf_dma_stall_cycles_i;
      REG_PERF_NOC:  mmio_rdata_o = perf_noc_flits_i;
      default:       mmio_rdata_o = 32'd0;
    endcase
  end

  assign accel_start_o = start_pending_q && !accel_busy_i;
  assign accel_desc_o = desc_q;
  assign mmio_ready_o = mmio_valid_i;
  assign irq_o = irq_en_q && done_seen_q;
endmodule
