// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Direct digital synthesizer that produces a square wave from a phase accumulator MSB.
// Accepts a frequency tuning word and system clock for the V2 audio-style generator.
// Legacy module used only by ro_top_v2.

`timescale 1ns / 1ps

module dds_core #(
    parameter int F_CLK_HZ = 12_000_000
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        en,
    input  logic [31:0] freq_hz,
    output logic        dds_out,
    output logic [31:0] phase_out
);

  logic [31:0] ftw;
  logic [31:0] phase;

  freq_to_ftw #(
      .F_CLK_HZ(F_CLK_HZ)
  ) u_ftw (
      .freq_hz(freq_hz),
      .ftw    (ftw)
  );

  dds_phase_accum u_accum (
      .clk  (clk),
      .rst_n(rst_n),
      .en   (en),
      .ftw  (ftw),
      .phase(phase)
  );

  assign phase_out = phase;
  assign dds_out   = phase[31];

endmodule : dds_core
