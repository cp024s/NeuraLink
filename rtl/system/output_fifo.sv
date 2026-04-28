module output_fifo #(
  parameter int DATA_W = 8,
  parameter int DEPTH = 32
) (
  input  logic              clk_i,
  input  logic              rst_ni,
  input  logic              clear_i,
  input  logic              push_i,
  input  logic [DATA_W-1:0] data_i,
  input  logic              pop_i,
  output logic [DATA_W-1:0] data_o,
  output logic              full_o,
  output logic              empty_o,
  output logic [$clog2(DEPTH+1)-1:0] count_o
);
  logic [DATA_W-1:0] mem_q [DEPTH];
  logic [$clog2(DEPTH)-1:0] rd_ptr_q, wr_ptr_q;
  logic [$clog2(DEPTH+1)-1:0] count_q;

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      rd_ptr_q <= '0;
      wr_ptr_q <= '0;
      count_q <= '0;
    end else if (clear_i) begin
      rd_ptr_q <= '0;
      wr_ptr_q <= '0;
      count_q <= '0;
    end else begin
      if (push_i && !full_o) begin
        mem_q[wr_ptr_q] <= data_i;
        wr_ptr_q <= wr_ptr_q + 1'b1;
      end

      if (pop_i && !empty_o) begin
        rd_ptr_q <= rd_ptr_q + 1'b1;
      end

      unique case ({(push_i && !full_o), (pop_i && !empty_o)})
        2'b10: count_q <= count_q + 1'b1;
        2'b01: count_q <= count_q - 1'b1;
        default: count_q <= count_q;
      endcase
    end
  end

  assign data_o = mem_q[rd_ptr_q];
  assign full_o = (count_q == DEPTH);
  assign empty_o = (count_q == 0);
  assign count_o = count_q;
endmodule

