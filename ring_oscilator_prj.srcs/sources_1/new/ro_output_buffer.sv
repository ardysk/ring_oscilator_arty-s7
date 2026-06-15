//--------------------------------------------------------------------------------
// Company:       CSD Lab6
// Engineer:      Ring Oscillator Project
//
// Create Date:   2026-06-06
// Design Name:   ro_output_buffer
// Module Name:   ro_output_buffer
// Project Name:  ring_oscilator_prj
// Target Devices: Xilinx Arty S7-50 (XC7S50-CSGA324)
// Tool Versions: Vivado 2018.3
// Description:   Bufor wyjścia pierścienia — BUFGCE na sygnale po MUX/dzielniku.
//                Nie dotyka pętli kombinacyjnej pierścienia; poprawia zbocza na pinie.
//
// Dependencies:  none (Xilinx BUFGCE primitive)
//
// Revision:
// Revision 0.01 - File Created
//--------------------------------------------------------------------------------
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
