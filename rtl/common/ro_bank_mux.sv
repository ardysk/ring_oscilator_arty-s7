// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Simple multiplexer that selects one of several ring bank outputs.
// Legacy building block for early multi-bank tops and the V2 design.
// Superseded in V1 by ro_multi_div_mux but kept for archival builds.

`timescale 1ns / 1ps

module ro_bank_mux #(
    parameter int RO_BANKS = 8
) (
    input  logic [RO_BANKS-1:0]              ring_out_bank,
    input  logic [((RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS)) - 1:0] bank_sel,
    output logic                             ro_out
);

  localparam int SEL_W = (RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS);

  logic [SEL_W-1:0] bank_eff;

  always_comb begin
    bank_eff = SEL_W'(bank_sel);
    if (RO_BANKS > 1 && SEL_W'(bank_sel) >= SEL_W'(RO_BANKS)) bank_eff = '0;
  end

  generate
    if (RO_BANKS <= 1) begin : g_one
      assign ro_out = ring_out_bank[0];
    end else begin : g_mux
      assign ro_out = ring_out_bank[bank_eff];
    end
  endgenerate

endmodule : ro_bank_mux
