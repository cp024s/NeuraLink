module pe_array #(
  parameter int ROWS   = 4,
  parameter int COLS   = 4,
  parameter int DATA_W = 8,
  parameter int ACC_W  = 24
) (
  input  logic                     clk_i,
  input  logic                     rst_ni,
  input  logic                     clear_i,
  input  logic signed [DATA_W-1:0] a_west_i [ROWS],
  input  logic signed [DATA_W-1:0] b_north_i [COLS],
  input  logic                     a_valid_west_i [ROWS],
  input  logic                     b_valid_north_i [COLS],
  output logic signed [ACC_W-1:0]  acc_o [ROWS][COLS],
  output logic                     acc_valid_o [ROWS][COLS]
);
  logic signed [DATA_W-1:0] a_west_q [ROWS];
  logic signed [DATA_W-1:0] b_north_q [COLS];
  logic a_valid_west_q [ROWS];
  logic b_valid_north_q [COLS];

  logic signed [DATA_W-1:0] a_bus [ROWS][COLS+1];
  logic signed [DATA_W-1:0] b_bus [ROWS+1][COLS];
  logic a_valid_bus [ROWS][COLS+1];
  logic b_valid_bus [ROWS+1][COLS];

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      for (int r = 0; r < ROWS; r++) begin
        a_west_q[r] <= '0;
        a_valid_west_q[r] <= 1'b0;
      end
      for (int c = 0; c < COLS; c++) begin
        b_north_q[c] <= '0;
        b_valid_north_q[c] <= 1'b0;
      end
    end else begin
      for (int r = 0; r < ROWS; r++) begin
        a_west_q[r] <= a_west_i[r];
        a_valid_west_q[r] <= a_valid_west_i[r];
      end
      for (int c = 0; c < COLS; c++) begin
        b_north_q[c] <= b_north_i[c];
        b_valid_north_q[c] <= b_valid_north_i[c];
      end
    end
  end

  genvar r, c;
  generate
    for (r = 0; r < ROWS; r++) begin : gen_row_seed
      assign a_bus[r][0] = a_west_q[r];
      assign a_valid_bus[r][0] = a_valid_west_q[r];
    end

    for (c = 0; c < COLS; c++) begin : gen_col_seed
      assign b_bus[0][c] = b_north_q[c];
      assign b_valid_bus[0][c] = b_valid_north_q[c];
    end

    for (r = 0; r < ROWS; r++) begin : gen_rows
      for (c = 0; c < COLS; c++) begin : gen_cols
        mac_pe #(
          .DATA_W(DATA_W),
          .ACC_W(ACC_W)
        ) u_pe (
          .clk_i(clk_i),
          .rst_ni(rst_ni),
          .clear_i(clear_i),
          .a_i(a_bus[r][c]),
          .b_i(b_bus[r][c]),
          .a_valid_i(a_valid_bus[r][c]),
          .b_valid_i(b_valid_bus[r][c]),
          .a_o(a_bus[r][c+1]),
          .b_o(b_bus[r+1][c]),
          .a_valid_o(a_valid_bus[r][c+1]),
          .b_valid_o(b_valid_bus[r+1][c]),
          .acc_o(acc_o[r][c]),
          .acc_valid_o(acc_valid_o[r][c])
        );
      end
    end
  endgenerate
endmodule
