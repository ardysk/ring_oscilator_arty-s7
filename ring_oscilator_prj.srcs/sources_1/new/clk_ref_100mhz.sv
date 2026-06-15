// MMCM: 12 MHz -> 100 MHz reference for 1 ms measurement gate.
`timescale 1ns / 1ps

module clk_ref_100mhz (
    input  logic clk_12mhz,
    input  logic rst_n,
    output logic clk_100mhz,
    output logic locked
);

  logic clkfb;
  logic clkfb_buf;
  logic clkout_unbuf;
  wire  mmcm_rst = ~rst_n;

  BUFG u_bufg_fb (.I(clkfb), .O(clkfb_buf));
  BUFG u_bufg_out (.I(clkout_unbuf), .O(clk_100mhz));

  MMCME2_BASE #(
      .BANDWIDTH        ("OPTIMIZED"),
      .CLKFBOUT_MULT_F  (50.0),
      .CLKFBOUT_PHASE   (0.0),
      .CLKIN1_PERIOD    (83.333),
      .DIVCLK_DIVIDE    (1),
      .CLKOUT0_DIVIDE_F (6.0),
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT0_PHASE    (0.0)
  ) u_mmcm (
      .CLKIN1    (clk_12mhz),
      .CLKFBIN   (clkfb_buf),
      .CLKFBOUT  (clkfb),
      .CLKOUT0   (clkout_unbuf),
      .LOCKED    (locked),
      .PWRDWN    (1'b0),
      .RST       (mmcm_rst)
  );

endmodule
