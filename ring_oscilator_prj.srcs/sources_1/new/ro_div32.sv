// 32-bit half-period toggle divider on ring clock.
`timescale 1ns / 1ps

module ro_div32 (
    input  logic        rst_n,
    input  logic        ro_clk,
    input  logic        bypass,
    input  logic [31:0] half_edges,
    output logic        div_out
);

  ring_prog_toggle_div #(
      .CNT_W(32)
  ) u_div (
      .rst_n      (rst_n),
      .ro_clk     (ro_clk),
      .bypass     (bypass),
      .half_edges (half_edges),
      .div_out    (div_out)
  );

endmodule
