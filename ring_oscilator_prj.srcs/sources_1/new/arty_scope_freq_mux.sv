// Arty S7 — wyjśćie JA jako próbkowany sygnał z pierścienia (inwersory LUT).
// MMCM nadal dostarcza (~600 MHz) tylko domenę próbkującą (synchronizacja + jitter redukcji);
// żadnego „źródła f„ z dzielnika — presety częściotliwości obsługuje wyłącznie strojenie RO (patrz ro_top_arty.sv).
//
`timescale 1ns / 1ps

module arty_scope_freq_mux (
    input  wire clk_in_12mhz,
    input  wire rst_n,
    input  wire raw_ring_sig,
    output wire scope_out,
    output wire pll_locked
);

  wire clk_fb_o;
  wire clk_fb_buf;
  wire clk_out_unbuf;
  wire clk600;
  wire locked;
  assign pll_locked = locked;
  wire mmcm_rst = ~rst_n;

  BUFG bufg_fb (
      .I(clk_fb_o),
      .O(clk_fb_buf)
  );

  BUFG bufg_out (
      .I(clk_out_unbuf),
      .O(clk600)
  );

  MMCME2_BASE #(
      .BANDWIDTH           ("OPTIMIZED"),
      .CLKFBOUT_MULT_F     (50.0),
      .CLKFBOUT_PHASE      (0.0),
      .CLKIN1_PERIOD       (83.333),
      .DIVCLK_DIVIDE       (1),
      .CLKOUT0_DIVIDE_F    (1.0),
      .CLKOUT0_DUTY_CYCLE  (0.5),
      .CLKOUT0_PHASE       (0.0)
  ) u_mmcm (
      .CLKFBOUT(clk_fb_o),
      .CLKFBOUTB (),
      .CLKFBIN (clk_fb_buf),
      .CLKIN1  (clk_in_12mhz),
      .PWRDWN  (1'b0),
      .RST     (mmcm_rst),
      .CLKOUT0 (clk_out_unbuf),
      .CLKOUT0B(),
      .CLKOUT1 (),
      .CLKOUT1B(),
      .CLKOUT2 (),
      .CLKOUT2B(),
      .CLKOUT3 (),
      .CLKOUT3B(),
      .CLKOUT4 (),
      .CLKOUT5 (),
      .CLKOUT6 (),
      .LOCKED  (locked)
  );

  logic ext_rst_hi;
  logic ext_rst_ok;

  always_ff @(posedge clk600 or negedge rst_n) begin
    if (!rst_n) begin
      ext_rst_hi <= 1'b0;
      ext_rst_ok <= 1'b0;
    end else begin
      ext_rst_hi <= 1'b1;
      ext_rst_ok <= ext_rst_hi;
    end
  end

  logic pll_allow;
  assign pll_allow = ext_rst_ok & locked;

  (* ASYNC_REG = "true" *)
  logic rraw_a, rraw_b, rraw_c;
  always_ff @(posedge clk600 or negedge rst_n) begin
    if (!rst_n) begin
      rraw_a <= 1'b0;
      rraw_b <= 1'b0;
      rraw_c <= 1'b0;
    end else if (!pll_allow) begin
      rraw_a <= 1'b0;
      rraw_b <= 1'b0;
      rraw_c <= 1'b0;
    end else begin
      rraw_a <= raw_ring_sig;
      rraw_b <= rraw_a;
      rraw_c <= rraw_b;
    end
  end

  logic scope_reg;
  always_ff @(posedge clk600 or negedge rst_n) begin
    if (!rst_n) scope_reg <= 1'b0;
    else if (!pll_allow) scope_reg <= 1'b0;
    else scope_reg <= rraw_c;
  end

  assign scope_out = scope_reg;

endmodule : arty_scope_freq_mux
