// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Combines per-bank buffered ring outputs, target mapping, and the programmable divider.
// Selects the active bank and drives both scope output and measurement taps.
// Central output routing block between the sixteen rings and ro_sig_buf.

`timescale 1ns / 1ps

module ro_multi_div_mux #(
    parameter int RO_BANKS   = 16,
    parameter int DIV_CNT_W  = 32,
    parameter int BANK_SEL_W = (RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS)
) (
    input  logic                  rst_n,
    input  logic [15:0]           target_khz,
    input  logic                  bank_manual,
    input  logic                  div_manual,
    input  logic                  csr_div_bypass,
    input  logic [31:0]           csr_half_edges,
    input  logic [RO_BANKS-1:0]   ring_bank_raw,
    input  logic [BANK_SEL_W-1:0] bank_sel,
    input  logic [BANK_SEL_W-1:0] bank_override,
    output logic [BANK_SEL_W-1:0] bank_auto,
    output logic [DIV_CNT_W-1:0]  half_edges,
    output logic                  div_bypass,
    output logic                  div_mux_out,
    output logic                  ring_scope_sig,
    output logic                  ring_meas_sig,
    output logic [15:0]           f_pred_khz
);

  logic [RO_BANKS-1:0]      ring_bank_buf;
  logic [BANK_SEL_W-1:0]    bank_pick;
  logic [DIV_CNT_W-1:0]     map_half;
  logic                     map_bypass;
  logic                     ring_sel;
  logic                     div_raw;
  logic [DIV_CNT_W-1:0]     half_eff;
  logic                     bypass_eff;

  ro_ring_bank_buf #(
      .RO_BANKS(RO_BANKS)
  ) u_ring_buf (
      .ring_in (ring_bank_raw),
      .ring_buf(ring_bank_buf)
  );

  ro_target_map #(
      .BANK_SEL_W(BANK_SEL_W),
      .RO_BANKS  (RO_BANKS),
      .DIV_CNT_W (DIV_CNT_W)
  ) u_map (
      .target_khz    (target_khz),
      .bank_manual   (bank_manual),
      .bank_override (bank_override),
      .bank_auto     (bank_pick),
      .half_edges    (map_half),
      .div_bypass    (map_bypass),
      .f_pred_khz    (f_pred_khz)
  );

  assign bank_auto = bank_pick;
  assign half_eff  = div_manual ? DIV_CNT_W'(csr_half_edges) : map_half;
  assign bypass_eff = 1'b0;
  assign half_edges = half_eff;
  assign div_bypass = bypass_eff;
  assign ring_sel   = ring_bank_buf[bank_sel];

  ring_prog_toggle_div #(
      .CNT_W(DIV_CNT_W)
  ) u_div (
      .rst_n      (rst_n),
      .ro_clk     (ring_sel),
      .bypass     (bypass_eff),
      .half_edges (half_eff),
      .div_out    (div_raw)
  );

  assign div_mux_out    = div_raw;
  assign ring_scope_sig = ring_sel;
  assign ring_meas_sig  = ring_sel;

endmodule : ro_multi_div_mux
