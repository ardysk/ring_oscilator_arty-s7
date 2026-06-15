// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Buffers the final divided output with a BUFG for clean scope drive on JA.
// Sits after the programmable divider on the main synthesizer output path.
// Used in V1 instead of a clock-enabled buffer for continuous output viewing.

`timescale 1ns / 1ps

module ro_sig_buf (
    input  logic sig_in,
    output logic sig_out
);

  BUFG u_bufg (
      .I(sig_in),
      .O(sig_out)
  );

endmodule
