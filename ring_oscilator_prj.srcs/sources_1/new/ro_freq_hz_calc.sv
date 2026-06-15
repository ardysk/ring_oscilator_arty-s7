// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Computes output frequency in hertz from a gated edge count and reference clock.
// Implements f = edges * f_ref / (2 * gate_cycles) with optional scaling.
// Instantiated inside ro_freq_measure for hardware frequency readout.

`timescale 1ns / 1ps

module ro_freq_hz_calc #(
    parameter int F_REF_HZ = 12_000_000
) (
    input  logic [31:0] gate_cycles,
    input  logic [31:0] edge_count,
    output logic [31:0] freq_hz
);

  logic [63:0] numerator;
  logic [63:0] denominator;

  always_comb begin
    if (gate_cycles == 32'd0) begin
      freq_hz = 32'hFFFF_FFFF;
    end else begin
      numerator   = 64'(edge_count) * 64'(F_REF_HZ);
      denominator = 64'(gate_cycles);
      freq_hz     = 32'(numerator / denominator);
    end
  end

endmodule
