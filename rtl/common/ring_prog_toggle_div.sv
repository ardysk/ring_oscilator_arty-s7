// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Programmable frequency divider that counts rising edges on the selected ring signal.
// Generates a divided square wave; minimum division is two when half_edges equals one.
// Sits on the output path so scope signals always pass through a divider in V1.

`timescale 1ns / 1ps

module ring_prog_toggle_div #(
    parameter int CNT_W = 8
) (
    input  logic                  rst_n,
    input  logic                  ro_clk,
    input  logic                  bypass,
    input  logic [      CNT_W-1:0] half_edges,  // min 1 ustawiane w nadmiarze RTL
    output logic                  div_out
);

  (* KEEP = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  logic [CNT_W-1:0] cnt;
  (* KEEP = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  logic             div_toggle;
  logic [CNT_W-1:0] half_eff;

  assign half_eff = (half_edges < CNT_W'(1)) ? CNT_W'(1) : half_edges;

  always_ff @(posedge ro_clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt        <= '0;
      div_toggle <= 1'b0;
    end else if (half_eff <= CNT_W'(1)) begin
      cnt        <= '0;
      div_toggle <= ~div_toggle;
    end else if (cnt >= half_eff - 1'b1) begin
      cnt        <= '0;
      div_toggle <= ~div_toggle;
    end else cnt <= cnt + 1'b1;
  end

  assign div_out = div_toggle;

endmodule : ring_prog_toggle_div
