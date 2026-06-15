// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Asynchronous prescaler that divides a fast ring output before frequency measurement.
// Reduces edge rate seen by the 12 MHz counter to avoid aliasing on very fast rings.
// Used on slow chain banks and inside ro_bank_prescale_mux per bank class.

`timescale 1ns / 1ps

module ro_ring_prescale #(
    parameter int DIV_BITS = 9
) (
    input  logic ro_in,
    input  logic rst_n,
    output logic ro_div
);

  (* KEEP = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  logic [DIV_BITS-1:0] cnt;
  (* KEEP = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  logic              toggle;

  always_ff @(posedge ro_in or negedge rst_n) begin
    if (!rst_n) begin
      cnt    <= '0;
      toggle <= 1'b0;
    end else if (cnt == {DIV_BITS{1'b1}}) begin
      cnt    <= '0;
      toggle <= ~toggle;
    end else begin
      cnt <= cnt + 1'b1;
    end
  end

  assign ro_div = toggle;

endmodule
