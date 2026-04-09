module perf_counter_block (
  input  logic        clk_i,
  input  logic        rst_ni,
  input  logic        enable_i,
  input  logic        pe_active_i,
  input  logic        dma_stall_i,
  input  logic [15:0] noc_flits_i,
  output logic [31:0] pe_active_cycles_o,
  output logic [31:0] pe_idle_cycles_o,
  output logic [31:0] dma_stall_cycles_o,
  output logic [31:0] noc_flit_count_o
);
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      pe_active_cycles_o <= '0;
      pe_idle_cycles_o <= '0;
      dma_stall_cycles_o <= '0;
      noc_flit_count_o <= '0;
    end else if (enable_i) begin
      if (pe_active_i) pe_active_cycles_o <= pe_active_cycles_o + 1'b1;
      else pe_idle_cycles_o <= pe_idle_cycles_o + 1'b1;

      if (dma_stall_i) dma_stall_cycles_o <= dma_stall_cycles_o + 1'b1;
      noc_flit_count_o <= noc_flit_count_o + noc_flits_i;
    end
  end
endmodule
