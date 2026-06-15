// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Synchronizes an asynchronous ring oscillator signal into the system clock domain.
// Uses a multi-flop metastability buffer before edge counting or control logic.
// Feeds ro_freq_measure and related blocks that operate on clk at 12 MHz.

`timescale 1ns / 1ps

module ro_async_to_ref_sync #(
    parameter int STAGES = 3
) (
    input  logic clk,
    input  logic rst_n,
    input  logic ro_async,
    output logic ro_sync
);

  generate
    if (STAGES < 2) begin : gen_bad_stages
      initial $fatal(1, "ro_async_to_ref_sync: STAGES must be >= 2");
    end
  endgenerate

  (* ASYNC_REG = "true" *)
  logic [STAGES-1:0] chain_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) chain_q <= '0;
    else chain_q <= {chain_q[STAGES-2:0], ro_async};
  end

  assign ro_sync = chain_q[STAGES-1];

endmodule : ro_async_to_ref_sync
