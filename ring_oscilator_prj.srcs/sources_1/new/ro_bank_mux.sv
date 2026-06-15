//--------------------------------------------------------------------------------
// Company:       CSD Lab6
// Engineer:      Ring Oscillator Project
//
// Create Date:   2026-06-06
// Design Name:   ro_bank_mux
// Module Name:   ro_bank_mux
// Project Name:  ring_oscilator_prj
// Target Devices: Xilinx Arty S7-50 (XC7S50-CSGA324)
// Tool Versions: Vivado 2018.3
// Description:   Multiplekser wyboru banku pierścienia — sterowanie z zewnątrz
//                bez bezpośredniego dotykania pętli LUT każdego banku.
//
// Dependencies:  none
//
// Revision:
// Revision 0.01 - File Created
//--------------------------------------------------------------------------------
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
