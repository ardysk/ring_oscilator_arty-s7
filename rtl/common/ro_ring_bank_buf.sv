// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Places a global clock buffer on each ring bank output before muxing.
// Isolates combinational RO loops from downstream load and routing delay.
// One instance per bank in ro_multi_div_mux.

`timescale 1ns / 1ps

module ro_ring_bank_buf #(
    parameter int RO_BANKS = 8
) (
    input  logic [RO_BANKS-1:0] ring_in,
    output logic [RO_BANKS-1:0] ring_buf
);

  generate
    genvar gi;
    for (gi = 0; gi < RO_BANKS; gi++) begin : g_buf
      BUFG u_bufg (
          .I(ring_in[gi]),
          .O(ring_buf[gi])
      );
    end
  endgenerate

endmodule
