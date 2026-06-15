`timescale 1ns / 1ps

module ro_top_v2 #(
    parameter int RO_NUM_TUNE_BITS            = 10,
    parameter int RO_NUM_TAIL_INVERTERS       = 2,
    parameter int RO_BANKS                    = 8,
    parameter int DIV_CNT_W                   = 16,
    parameter int TARGET_MHZ_MAX              = 511,
    parameter int DIV_BYPASS_ABOVE_MHZ        = 60,
    parameter int unsigned F_RO_EST_MHZ_BANK0 = 48,
    parameter int unsigned F_RO_EST_MHZ_BANK7 = 185,
    parameter [31:0] MEAS_GATE_CYCLES_DEFAULT = 32'd60_000
) (
    input  logic        clk_12mhz,
    input  logic [3:0]  btn,
    output logic [3:0]  led,
    output logic        ro_scope,
    output logic        ro_scope_ring,
    output logic        dds_out
);

  localparam int BANK_SEL_W = (RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS);
  localparam int TUNE_BW    = RO_BANKS * RO_NUM_TUNE_BITS;

  logic rst_n;
  assign rst_n = ~btn[3];

  logic btn_up_db, btn_dn_db, btn_ms_db;
  logic btn_up_pe, btn_dn_pe, btn_ms_pe;

  btn_debouncer u_db_up (
      .clk(clk_12mhz), .rst_n(rst_n), .btn_raw(btn[0]),
      .btn_stable(btn_up_db), .btn_posedge(btn_up_pe));
  btn_debouncer u_db_dn (
      .clk(clk_12mhz), .rst_n(rst_n), .btn_raw(btn[1]),
      .btn_stable(btn_dn_db), .btn_posedge(btn_dn_pe));
  btn_debouncer u_db_ms (
      .clk(clk_12mhz), .rst_n(rst_n), .btn_raw(btn[2]),
      .btn_stable(btn_ms_db), .btn_posedge(btn_ms_pe));

  logic [8:0]  target_mhz;
  logic        meas_pulse;

  btn_freq_selector u_sel (
      .clk(clk_12mhz),
      .rst_n(rst_n),
      .btn_up_pulse  (btn_up_pe),
      .btn_dn_pulse  (btn_dn_pe),
      .btn_meas_pulse(btn_ms_pe),
      .target_mhz(target_mhz),
      .meas_pulse(meas_pulse)
  );

  logic [31:0] dds_freq_hz;
  assign dds_freq_hz = 32'(target_mhz) * 32'd1_000_000;

  dds_core #(
      .F_CLK_HZ(12_000_000)
  ) u_dds (
      .clk    (clk_12mhz),
      .rst_n  (rst_n),
      .en     (1'b1),
      .freq_hz(dds_freq_hz),
      .dds_out(dds_out),
      .phase_out()
  );

  logic [BANK_SEL_W-1:0] ro_bank_auto;
  logic [DIV_CNT_W-1:0]  half_edges_eff;
  logic                  div_bypass;
  logic [RO_BANKS * DIV_CNT_W-1:0] half_edges_bus;
  logic [RO_BANKS-1:0]             div_bypass_bus;
  logic [8:0]                      f_pred_unused;

  ro_target_map #(
      .BANK_SEL_W(BANK_SEL_W),
      .RO_BANKS  (RO_BANKS),
      .DIV_CNT_W (DIV_CNT_W)
  ) u_target (
      .target_mhz     (target_mhz),
      .bank_sel       (ro_bank_auto),
      .half_edges_bus (half_edges_bus),
      .div_bypass_bus (div_bypass_bus),
      .f_pred_mhz     (f_pred_unused)
  );

  assign half_edges_eff = half_edges_bus[ro_bank_auto * DIV_CNT_W+:DIV_CNT_W];
  assign div_bypass     = div_bypass_bus[ro_bank_auto];

  logic [TUNE_BW-1:0] ro_tune_bus;

  ro_bank_tune_pack #(
      .NUM_BANKS    (RO_BANKS),
      .NUM_TUNE_BITS(RO_NUM_TUNE_BITS)
  ) u_tune_pack (
      .ro_tune_bus(ro_tune_bus)
  );

  logic        ro_en;
  logic        meas_start;
  logic [31:0] meas_gate_cycles;
  logic        ro_out;
  logic        meas_busy, meas_done;
  logic [31:0] meas_edge_count, meas_freq_hz;
  logic        pll_fb;

  assign ro_en            = 1'b1;
  assign meas_start       = meas_pulse;
  assign meas_gate_cycles = MEAS_GATE_CYCLES_DEFAULT;

  ro_top #(
      .RO_BANKS               (RO_BANKS),
      .RO_NUM_TUNE_BITS      (RO_NUM_TUNE_BITS),
      .RO_NUM_TAIL_INVERTERS (RO_NUM_TAIL_INVERTERS)
  ) u_core (
      .clk              (clk_12mhz),
      .rst_n            (rst_n),
      .ro_en            (ro_en),
      .ro_tune_sel      (ro_tune_bus),
      .ro_bank_sel      (ro_bank_auto),
      .meas_start       (meas_start),
      .meas_gate_cycles (meas_gate_cycles),
      .ro_out           (ro_out),
      .meas_busy        (meas_busy),
      .meas_done        (meas_done),
      .meas_edge_count  (meas_edge_count),
      .meas_freq_hz     (meas_freq_hz)
  );

  logic ro_scope_muxed, ro_buffered;

  ring_prog_toggle_div #(
      .CNT_W(DIV_CNT_W)
  ) u_hz_scope_div (
      .rst_n      (rst_n),
      .ro_clk     (ro_out),
      .bypass     (div_bypass),
      .half_edges (half_edges_eff),
      .div_out    (ro_scope_muxed)
  );

  ro_output_buffer u_ro_buf (
      .clk   (clk_12mhz),
      .rst_n (rst_n),
      .ro_in (ro_scope_muxed),
      .ro_out(ro_buffered)
  );

  arty_scope_freq_mux u_scope (
      .clk_in_12mhz (clk_12mhz),
      .rst_n        (rst_n),
      .raw_ring_sig (ro_buffered),
      .scope_out    (ro_scope),
      .pll_locked   (pll_fb)
  );

  arty_scope_freq_mux u_scope_ring (
      .clk_in_12mhz (clk_12mhz),
      .rst_n        (rst_n),
      .raw_ring_sig (ro_out),
      .scope_out    (ro_scope_ring),
      .pll_locked   ()
  );

  assign led = meas_busy ? 4'hA : target_mhz[3:0];

endmodule : ro_top_v2
