module mac_pe #(
  parameter int DATA_W = 8,
  parameter int ACC_W  = 24,
  parameter bit SPARSE_SKIP_EN = 1'b1
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     clear_i,
  input  logic signed [DATA_W-1:0] a_i,
  input  logic signed [DATA_W-1:0] b_i,
  input  logic                     a_valid_i,
  input  logic                     b_valid_i,
  output logic signed [DATA_W-1:0] a_o,
  output logic signed [DATA_W-1:0] b_o,
  output logic                     a_valid_o,
  output logic                     b_valid_o,
  output logic signed [ACC_W-1:0]  acc_o,
  output logic                     acc_valid_o
);
  logic mul_valid;
  logic do_mac;
  logic signed [2*DATA_W-1:0] product;
  logic signed [ACC_W-1:0] product_ext;
  logic signed [ACC_W-1:0] acc_q;

  // Use strict valid checks to avoid X-propagation at simulation bring-up.
  assign mul_valid = (a_valid_i === 1'b1) & (b_valid_i === 1'b1);
  assign do_mac = mul_valid & (~SPARSE_SKIP_EN | ((a_i != '0) & (b_i != '0)));
  assign product = a_i * b_i;
  assign product_ext = {{(ACC_W-(2*DATA_W)){product[2*DATA_W-1]}}, product};

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      a_o        <= '0;
      b_o        <= '0;
      a_valid_o  <= 1'b0;
      b_valid_o  <= 1'b0;
      acc_q      <= '0;
      acc_valid_o <= 1'b0;
    end else begin
      a_o       <= a_i;
      b_o       <= b_i;
      a_valid_o <= a_valid_i;
      b_valid_o <= b_valid_i;

      if (clear_i) begin
        acc_q <= '0;
        acc_valid_o <= 1'b0;
      end else if (do_mac) begin
        acc_q <= acc_q + product_ext;
        acc_valid_o <= 1'b1;
      end else begin
        acc_valid_o <= 1'b0;
      end
    end
  end

  assign acc_o = acc_q;
endmodule
