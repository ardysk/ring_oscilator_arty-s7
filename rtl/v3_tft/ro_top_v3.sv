// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Top-level that adds GC9A01 TFT display support alongside the RO measurement path.
// Archived V3 variant; display bring-up was not completed in the shipped V1 release.
// Combines SPI display driver hooks with ring frequency status outputs.

`timescale 1ns / 1ps

module ro_top_v3 (
    input  wire        clk_12mhz,
    input  wire [3:0]  btn,
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    input  wire [15:0] s_axi_awaddr,
    input  wire [ 2:0] s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    input  wire [31:0] s_axi_wdata,
    input  wire [ 3:0] s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    output wire [ 1:0] s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    input  wire [15:0] s_axi_araddr,
    input  wire [ 2:0] s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    output wire [31:0] s_axi_rdata,
    output wire [ 1:0] s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    output wire [3:0]  led,
    output wire        ro_scope,
    output wire        ro_scope_ring,
    output wire        tft_sck,
    output wire        tft_mosi,
    output wire        tft_cs_n,
    output wire        tft_dc,
    output wire        tft_rst_n
);

  wire [31:0] meas_freq_hz;
  wire [8:0]  target_mhz;
  wire        meas_done;
  wire        tft_busy;

  ro_top_arty_axi u_ro (
      .clk_12mhz(clk_12mhz),
      .btn(btn),
      .s_axi_aclk(s_axi_aclk),
      .s_axi_aresetn(s_axi_aresetn),
      .s_axi_awaddr(s_axi_awaddr),
      .s_axi_awprot(s_axi_awprot),
      .s_axi_awvalid(s_axi_awvalid),
      .s_axi_awready(s_axi_awready),
      .s_axi_wdata(s_axi_wdata),
      .s_axi_wstrb(s_axi_wstrb),
      .s_axi_wvalid(s_axi_wvalid),
      .s_axi_wready(s_axi_wready),
      .s_axi_bresp(s_axi_bresp),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bready(s_axi_bready),
      .s_axi_araddr(s_axi_araddr),
      .s_axi_arprot(s_axi_arprot),
      .s_axi_arvalid(s_axi_arvalid),
      .s_axi_arready(s_axi_arready),
      .s_axi_rdata(s_axi_rdata),
      .s_axi_rresp(s_axi_rresp),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(s_axi_rready),
      .led(led),
      .ro_scope(ro_scope),
      .ro_scope_ring(ro_scope_ring),
      .mon_freq_hz(meas_freq_hz),
      .mon_target_mhz(target_mhz),
      .mon_meas_done(meas_done)
  );

  gc9a01_driver u_tft (
      .clk(clk_12mhz),
      .rst_n(s_axi_aresetn & ~btn[3]),
      .freq_hz(meas_freq_hz),
      .target_mhz(target_mhz),
      .tft_sck(tft_sck),
      .tft_mosi(tft_mosi),
      .tft_cs_n(tft_cs_n),
      .tft_dc(tft_dc),
      .tft_rst_n(tft_rst_n),
      .busy(tft_busy)
  );

endmodule
