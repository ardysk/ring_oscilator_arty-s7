//--------------------------------------------------------------------------------
// Company:       CSD Lab6
// Engineer:      Ring Oscillator Project
//
// Create Date:   2026-06-06
// Design Name:   ro_top_v3_wrapper
// Module Name:   ro_top_v3_wrapper
// Project Name:  ring_oscilator_prj
// Target Devices: Xilinx Arty S7-50 (XC7S50-CSGA324)
// Tool Versions: Vivado 2018.3
// Description:   Wrapper V3 bez MicroBlaze — AXI idle, reset aktywny.
//
// Revision:
// Revision 0.01 - File Created
//--------------------------------------------------------------------------------
`timescale 1ns / 1ps

module ro_top_v3_wrapper (
    input  wire        clk_12mhz,
    input  wire [3:0]  btn,
    output wire [3:0]  led,
    output wire        ro_scope,
    output wire        ro_scope_ring,
    output wire        tft_sck,
    output wire        tft_mosi,
    output wire        tft_cs_n,
    output wire        tft_dc,
    output wire        tft_rst_n
);

  wire        s_axi_aclk    = clk_12mhz;
  wire        s_axi_aresetn = 1'b1;
  wire        s_axi_awready, s_axi_wready, s_axi_bvalid;
  wire [ 1:0] s_axi_bresp;
  wire        s_axi_arready, s_axi_rvalid;
  wire [31:0] s_axi_rdata;
  wire [ 1:0] s_axi_rresp;

  ro_top_v3 u_core (
      .clk_12mhz(clk_12mhz),
      .btn(btn),
      .s_axi_aclk(s_axi_aclk),
      .s_axi_aresetn(s_axi_aresetn),
      .s_axi_awaddr(16'h0),
      .s_axi_awprot(3'h0),
      .s_axi_awvalid(1'b0),
      .s_axi_awready(s_axi_awready),
      .s_axi_wdata(32'h0),
      .s_axi_wstrb(4'h0),
      .s_axi_wvalid(1'b0),
      .s_axi_wready(s_axi_wready),
      .s_axi_bresp(s_axi_bresp),
      .s_axi_bvalid(s_axi_bvalid),
      .s_axi_bready(1'b1),
      .s_axi_araddr(16'h0),
      .s_axi_arprot(3'h0),
      .s_axi_arvalid(1'b0),
      .s_axi_arready(s_axi_arready),
      .s_axi_rdata(s_axi_rdata),
      .s_axi_rresp(s_axi_rresp),
      .s_axi_rvalid(s_axi_rvalid),
      .s_axi_rready(1'b1),
      .led(led),
      .ro_scope(ro_scope),
      .ro_scope_ring(ro_scope_ring),
      .tft_sck(tft_sck),
      .tft_mosi(tft_mosi),
      .tft_cs_n(tft_cs_n),
      .tft_dc(tft_dc),
      .tft_rst_n(tft_rst_n)
  );

endmodule
