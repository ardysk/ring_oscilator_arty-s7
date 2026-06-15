// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Clock-enabled output buffer (BUFGCE) for gated RO or DDS paths.
// Legacy helper retained for the V2 button/DDS variant top level.
// Not used on the active V1 MicroBlaze UART code path.

`timescale 1ns / 1ps

module ro_output_buffer (
    input  logic clk,
    input  logic rst_n,
    input  logic ro_in,
    output logic ro_out
);

  logic ro_buf;

  BUFGCE u_bufgce (
      .I (ro_in),
      .CE(1'b1),
      .O (ro_buf)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) ro_out <= 1'b0;
    else        ro_out <= ro_buf;
  end

endmodule : ro_output_buffer
