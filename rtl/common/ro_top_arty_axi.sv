`timescale 1ns / 1ps

module ro_top_arty_axi #(
    parameter int RO_NUM_TUNE_BITS            = 12,
    parameter int RO_NUM_TAIL_INVERTERS       = 2,
    parameter int RO_BANKS                    = 16,
    parameter int DIV_CNT_W                   = 32,
    parameter int F_REF_HZ                    = 12_000_000,
    parameter [31:0] MEAS_GATE_CYCLES_DEFAULT = 32'd60_000
) (
    input  logic        clk_12mhz,
    input  logic [3:0]  btn,
    input  logic [3:0]  sw,
    input  logic        s_axi_aclk,
    input  logic        s_axi_aresetn,

    input  logic [15:0] s_axi_awaddr,
    input  logic [ 2:0] s_axi_awprot,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,

    input  logic [31:0] s_axi_wdata,
    input  logic [ 3:0] s_axi_wstrb,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,

    output logic [ 1:0] s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,

    input  logic [15:0] s_axi_araddr,
    input  logic [ 2:0] s_axi_arprot,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,

    output logic [31:0] s_axi_rdata,
    output logic [ 1:0] s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready,

    output logic [3:0]  led,
    output logic        ro_scope,
    output logic        ro_scope_ring,

    output logic [31:0] mon_freq_hz,
    output logic [ 8:0] mon_target_mhz,
    output logic        mon_meas_done
);

  localparam int BANK_SEL_W = (RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS);
  localparam int TUNE_BW    = RO_BANKS * RO_NUM_TUNE_BITS;

  logic rst_n;
  assign rst_n = s_axi_aresetn & ~btn[3];

  logic        csr_ro_en;
  logic        ro_en;
  logic        sw_any;
  assign sw_any = |sw;
  assign ro_en = csr_ro_en & (sw_any ? sw[0] : 1'b1);
  logic        meas_start;
  logic        csr_meas_pulse;
  logic        csr_meas_arm;
  logic        meas_arm_d;
  logic        csr_bank_manual;
  logic        csr_div_manual;
  logic        csr_div_bypass;
  logic [31:0] csr_half_edges;
  logic [31:0] meas_gate_cycles;
  logic        meas_busy_ring;
  logic        meas_done_ring;
  logic [31:0] meas_edge_count_ring;
  logic [31:0] meas_freq_hz_ring;
  logic        meas_busy_out;
  logic        meas_done_out;
  logic [31:0] meas_edge_count_out;
  logic [31:0] meas_freq_hz_out;
  logic        meas_busy;
  logic        meas_done;
  logic [3:0]  led_lat;
  logic        pll_fb;

  logic [15:0]                 csr_target_khz;
  logic [RO_NUM_TUNE_BITS-1:0] csr_tune_bits;
  logic [2:0]                  csr_freq_sel;
  logic [BANK_SEL_W-1:0]       csr_ro_bank_sel;
  logic [BANK_SEL_W-1:0]       ro_bank_auto;
  logic [BANK_SEL_W-1:0]       ro_bank_eff;
  logic [15:0]                 f_pred_khz;
  logic [RO_BANKS-1:0]         ring_out_bank_bus;

  logic [TUNE_BW-1:0] ro_tune_base;
  logic [TUNE_BW-1:0] ro_tune_bus;
  logic               div_mux_raw;
  logic               out_buf_sig;
  logic               ring_scope_raw;
  logic               ring_meas_raw;
  logic               ring_meas_prescaled;
  logic [31:0]        ring_meas_scale;
  logic [31:0]        meas_freq_hz_ring_scaled;
  logic [DIV_CNT_W-1:0] map_half_edges;
  logic                 map_div_bypass;

  always_ff @(posedge s_axi_aclk or negedge rst_n) begin
    if (!rst_n)
      meas_arm_d <= 1'b0;
    else
      meas_arm_d <= csr_meas_arm;
  end

  assign meas_start = csr_meas_arm & ~meas_arm_d;
  assign meas_busy  = meas_busy_ring | meas_busy_out;
  assign meas_done  = meas_done_ring & meas_done_out;
  assign ro_bank_eff = csr_bank_manual ? csr_ro_bank_sel : ro_bank_auto;

  csr_ro_axi_lite #(
      .RO_BANKS(RO_BANKS)
  ) u_csr (
      .s_axi_aclk (s_axi_aclk),
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
      .csr_ro_en(csr_ro_en),
      .csr_tune_sel(csr_tune_bits),
      .csr_freq_sel(csr_freq_sel),
      .csr_ro_bank_sel(csr_ro_bank_sel),
      .csr_bank_manual(csr_bank_manual),
      .csr_div_manual(csr_div_manual),
      .csr_div_bypass(csr_div_bypass),
      .csr_half_edges(csr_half_edges),
      .csr_meas_pulse(csr_meas_pulse),
      .csr_meas_arm(csr_meas_arm),
      .csr_meas_gate_cycles(meas_gate_cycles),
      .i_meas_busy(meas_busy),
      .i_meas_done(meas_done_out),
      .i_meas_ring_done(meas_done_ring),
      .i_meas_edge_count(meas_edge_count_out),
      .i_meas_freq_hz(meas_freq_hz_out),
      .i_meas_ring_edge_count(meas_edge_count_ring),
      .i_meas_ring_freq_hz(meas_freq_hz_ring),
      .i_pll_locked(pll_fb),
      .i_bank_active(ro_bank_eff),
      .i_bank_auto(ro_bank_auto),
      .i_div_bypass(map_div_bypass),
      .i_half_edges(map_half_edges),
      .i_f_pred_khz(f_pred_khz),
      .csr_target_khz(csr_target_khz)
  );

  ro_bank_tune_pack #(
      .NUM_BANKS    (RO_BANKS),
      .NUM_TUNE_BITS(RO_NUM_TUNE_BITS)
  ) u_tune_pack (
      .ro_tune_bus(ro_tune_base)
  );

  ro_multi_div_mux #(
      .RO_BANKS  (RO_BANKS),
      .DIV_CNT_W (DIV_CNT_W),
      .BANK_SEL_W(BANK_SEL_W)
  ) u_div_mux (
      .rst_n           (rst_n),
      .target_khz      (csr_target_khz),
      .bank_manual     (csr_bank_manual),
      .div_manual      (csr_div_manual),
      .csr_div_bypass  (csr_div_bypass),
      .csr_half_edges  (csr_half_edges),
      .ring_bank_raw   (ring_out_bank_bus),
      .bank_sel        (ro_bank_eff),
      .bank_override   (csr_ro_bank_sel),
      .bank_auto       (ro_bank_auto),
      .half_edges      (map_half_edges),
      .div_bypass      (map_div_bypass),
      .div_mux_out     (div_mux_raw),
      .ring_scope_sig  (ring_scope_raw),
      .ring_meas_sig   (ring_meas_raw),
      .f_pred_khz      (f_pred_khz)
  );

  ro_sig_buf u_out_buf (
      .sig_in (div_mux_raw),
      .sig_out(out_buf_sig)
  );

  ro_bank_prescale_mux #(
      .RO_BANKS  (RO_BANKS),
      .BANK_SEL_W(BANK_SEL_W)
  ) u_ring_ps (
      .ro_in    (ring_meas_raw),
      .rst_n    (rst_n),
      .bank_sel (ro_bank_eff),
      .ro_div   (ring_meas_prescaled),
      .scale_out(ring_meas_scale)
  );

  always_comb begin
    logic [63:0] prod;
    prod = 64'(meas_freq_hz_ring) * 64'(ring_meas_scale);
    if (prod > 64'hFFFF_FFFF)
      meas_freq_hz_ring_scaled = 32'hFFFF_FFFF;
    else
      meas_freq_hz_ring_scaled = prod[31:0];
  end

  generate
    genvar bi;
    for (bi = 0; bi < RO_BANKS; bi++) begin : g_tune_mux
      assign ro_tune_bus[(bi+1)*RO_NUM_TUNE_BITS-1 : bi*RO_NUM_TUNE_BITS] =
          (BANK_SEL_W'(bi) == ro_bank_eff) ? csr_tune_bits :
          ro_tune_base[(bi+1)*RO_NUM_TUNE_BITS-1 : bi*RO_NUM_TUNE_BITS];
    end
  endgenerate

  (* keep_hierarchy = "yes" *)
  ro_top #(
      .RO_BANKS               (RO_BANKS),
      .RO_NUM_TUNE_BITS      (RO_NUM_TUNE_BITS),
      .RO_NUM_TAIL_INVERTERS (RO_NUM_TAIL_INVERTERS),
      .MEAS_ENABLE           (1'b0)
  ) u_core (
      .clk              (clk_12mhz),
      .rst_n            (rst_n),
      .ro_en            (ro_en),
      .ro_tune_sel      (ro_tune_bus),
      .ro_bank_sel      (ro_bank_eff),
      .meas_start       (meas_start),
      .meas_gate_cycles (meas_gate_cycles),
      .ro_out           (),
      .ring_out_bank_bus(ring_out_bank_bus),
      .meas_busy        (),
      .meas_done        (),
      .meas_edge_count  (),
      .meas_freq_hz     ()
  );

  ro_freq_measure #(
      .F_REF_HZ(F_REF_HZ)
  ) u_meas_ring (
      .clk            (s_axi_aclk),
      .rst_n          (rst_n),
      .ro_async       (ring_meas_prescaled),
      .meas_start     (meas_start),
      .gate_cycles    (meas_gate_cycles),
      .meas_busy      (meas_busy_ring),
      .meas_done      (meas_done_ring),
      .meas_edge_count(meas_edge_count_ring),
      .meas_freq_hz   (meas_freq_hz_ring)
  );

  ro_freq_measure #(
      .F_REF_HZ(F_REF_HZ)
  ) u_meas_out (
      .clk            (s_axi_aclk),
      .rst_n          (rst_n),
      .ro_async       (out_buf_sig),
      .meas_start     (meas_start),
      .gate_cycles    (meas_gate_cycles),
      .meas_busy      (meas_busy_out),
      .meas_done      (meas_done_out),
      .meas_edge_count(meas_edge_count_out),
      .meas_freq_hz   (meas_freq_hz_out)
  );

  arty_scope_freq_mux u_scope (
      .clk_in_12mhz (clk_12mhz),
      .rst_n        (rst_n),
      .raw_ring_sig (out_buf_sig),
      .scope_out    (ro_scope),
      .pll_locked   (pll_fb)
  );

  arty_scope_freq_mux u_scope_ring (
      .clk_in_12mhz (clk_12mhz),
      .rst_n        (rst_n),
      .raw_ring_sig (ring_scope_raw),
      .scope_out    (ro_scope_ring),
      .pll_locked   ()
  );

  always_ff @(posedge clk_12mhz or negedge rst_n) begin
    if (!rst_n) led_lat <= '0;
    else if (meas_done) led_lat <= meas_freq_hz_out[3:0];
  end

  assign led = meas_busy ? 4'hA : 4'(ro_bank_eff);

  assign mon_freq_hz    = meas_freq_hz_out;
  assign mon_target_mhz = csr_target_khz[8:0];
  assign mon_meas_done  = meas_done;

endmodule : ro_top_arty_axi
