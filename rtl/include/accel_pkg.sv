`ifndef ACCEL_PKG_SV
`define ACCEL_PKG_SV

package accel_pkg;
  parameter int DATA_W = 8;
  parameter int ACC_W  = 24;
  parameter int MAX_ROWS = 16;
  parameter int MAX_COLS = 16;

  typedef enum logic [1:0] {
    DATAFLOW_WEIGHT_STATIONARY = 2'd0,
    DATAFLOW_OUTPUT_STATIONARY = 2'd1,
    DATAFLOW_ROW_STATIONARY    = 2'd2
  } dataflow_mode_e;

  typedef enum logic [3:0] {
    OP_GEMM        = 4'd0,
    OP_VECTOR      = 4'd1,
    OP_CONV2D      = 4'd2,
    OP_DEPTHWISE   = 4'd3,
    OP_POOLING     = 4'd4,
    OP_NORM        = 4'd5,
    OP_REDUCTION   = 4'd6,
    OP_ATTENTION   = 4'd7,
    OP_MATH        = 4'd8
  } op_class_e;

  typedef struct packed {
    logic [15:0] m;
    logic [15:0] n;
    logic [15:0] k;
    logic [31:0] a_base;
    logic [31:0] b_base;
    logic [31:0] c_base;
    dataflow_mode_e mode;
    op_class_e op_class;
    logic sparse_en;
  } tile_desc_t;
endpackage

`endif
