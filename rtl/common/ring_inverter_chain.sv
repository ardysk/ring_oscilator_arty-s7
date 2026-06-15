// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Implements a fixed-length chain of LUT inverters forming a slow ring oscillator.
// Provides stable low-frequency sources for banks B12 through B16 without software tuning.
// Instantiated in ro_top together with an optional output prescaler.

`timescale 1ns / 1ps

module ring_inverter_chain #(
    parameter int NUM_STAGES = 13
) (
    input  logic en,
    output logic ro_out
);
  localparam int N = NUM_STAGES;

  generate
    if (N < 3 || (N % 2) == 0) begin : gen_bad_param
      initial begin
        $error("ring_inverter_chain: NUM_STAGES must be odd and >= 3 (got %0d)", N);
      end
    end
  endgenerate

  (* KEEP = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  logic [N-1:0] ring_node;

  assign ring_node[0] = ~(ring_node[N-1] & en);

  genvar gi;
  generate
    for (gi = 1; gi < N; gi++) begin : g_inv
      assign ring_node[gi] = ~ring_node[gi-1];
    end
  endgenerate

  assign ro_out = ring_node[N-1];

endmodule : ring_inverter_chain
