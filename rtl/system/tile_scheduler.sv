`include "accel_pkg.sv"

module tile_scheduler #(
  parameter int Q_DEPTH = 16
) (
  input  logic                 clk_i,
  input  logic                 rst_ni,
  input  logic                 push_i,
  input  accel_pkg::tile_desc_t push_desc_i,
  input  logic                 pop_i,
  output accel_pkg::tile_desc_t pop_desc_o,
  output logic                 valid_o,
  output logic                 full_o,
  output logic                 empty_o
);
  import accel_pkg::*;

  tile_desc_t queue_mem [Q_DEPTH];
  logic [$clog2(Q_DEPTH)-1:0] rd_ptr_q, wr_ptr_q;
  logic [$clog2(Q_DEPTH+1)-1:0] count_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr_q <= '0;
      wr_ptr_q <= '0;
      count_q  <= '0;
    end else begin
      if (push_i && !full_o) begin
        queue_mem[wr_ptr_q] <= push_desc_i;
        wr_ptr_q <= wr_ptr_q + 1'b1;
      end
      if (pop_i && valid_o) begin
        rd_ptr_q <= rd_ptr_q + 1'b1;
      end
      case ({(push_i && !full_o), (pop_i && valid_o)})
        2'b10: count_q <= count_q + 1'b1;
        2'b01: count_q <= count_q - 1'b1;
        default: count_q <= count_q;
      endcase
    end
  end

  assign pop_desc_o = queue_mem[rd_ptr_q];
  assign valid_o = (count_q != 0);
  assign empty_o = (count_q == 0);
  assign full_o = (count_q == Q_DEPTH);
endmodule
