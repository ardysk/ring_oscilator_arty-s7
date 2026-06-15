// Plain-Verilog wrapper for Block Design references (Vivado 2018.3 rejects SV tops in BD Add Module).
// Instantiates ro_top_arty_axi.sv. AXI inferred as interface "S_AXI" for connection automation.

`timescale 1 ns / 1 ps

module ro_top_arty_axi_bd_wrap #(
    parameter RO_NUM_TUNE_BITS        = 12,
    parameter RO_NUM_TAIL_INVERTERS   = 2,
    parameter RO_BANKS                = 16,
    parameter [31:0] MEAS_GATE_CYCLES_DEFAULT = 32'd60_000
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0" *)
    (* X_INTERFACE_PARAMETER =
        "ASSOCIATED_BUSIF S_AXI,ASSOCIATED_RESET s_axi_aresetn,FREQ_HZ 12000000,INSERT_VIP 0" *)
    input  wire clk_12mhz,

    input  wire [3:0] btn,
    input  wire [3:0] sw,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0" *)
    (* X_INTERFACE_PARAMETER =
        "ASSOCIATED_BUSIF S_AXI,ASSOCIATED_RESET s_axi_aresetn,FREQ_HZ 12000000,INSERT_VIP 0" *)
    input  wire s_axi_aclk,

    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW,INSERT_VIP 0" *)
    input  wire s_axi_aresetn,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWADDR" *)
    (* X_INTERFACE_PARAMETER =
        "XIL_INTERFACENAME S_AXI,DATA_WIDTH 32,PROTOCOL AXI4LITE,ADDR_WIDTH 16,READ_WRITE_MODE READ_WRITE,SUPPORTS_NARROW_BURST 0" *)
    input  wire [15:0] s_axi_awaddr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWPROT" *)
    input  wire [ 2:0] s_axi_awprot,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWVALID" *)
    input  wire        s_axi_awvalid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI AWREADY" *)
    output wire        s_axi_awready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WDATA" *)
    input  wire [31:0] s_axi_wdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WSTRB" *)
    input  wire [ 3:0] s_axi_wstrb,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WVALID" *)
    input  wire        s_axi_wvalid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI WREADY" *)
    output wire        s_axi_wready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI BRESP" *)
    output wire [ 1:0] s_axi_bresp,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI BVALID" *)
    output wire        s_axi_bvalid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI BREADY" *)
    input  wire        s_axi_bready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARADDR" *)
    input  wire [15:0] s_axi_araddr,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARPROT" *)
    input  wire [ 2:0] s_axi_arprot,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARVALID" *)
    input  wire        s_axi_arvalid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI ARREADY" *)
    output wire        s_axi_arready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RDATA" *)
    output wire [31:0] s_axi_rdata,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RRESP" *)
    output wire [ 1:0] s_axi_rresp,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RVALID" *)
    output wire        s_axi_rvalid,

    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm_rtl:1.0 S_AXI RREADY" *)
    input  wire        s_axi_rready,

    output wire [3:0] led,
    output wire       ro_scope,
    output wire       ro_scope_ring
);

  ro_top_arty_axi #(
      .RO_BANKS             (RO_BANKS),
      .RO_NUM_TUNE_BITS     (RO_NUM_TUNE_BITS),
      .RO_NUM_TAIL_INVERTERS(RO_NUM_TAIL_INVERTERS),
      .MEAS_GATE_CYCLES_DEFAULT(MEAS_GATE_CYCLES_DEFAULT)
  ) u_inner (
      .clk_12mhz(clk_12mhz),
      .btn(btn),
      .sw(sw),
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
      .ro_scope_ring(ro_scope_ring)
  );

endmodule
