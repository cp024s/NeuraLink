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

  typedef struct packed {
    logic [15:0] m;
    logic [15:0] n;
    logic [15:0] k;
    logic [31:0] a_base;
    logic [31:0] b_base;
    logic [31:0] c_base;
    dataflow_mode_e mode;
    logic sparse_en;
  } tile_desc_t;
endpackage
