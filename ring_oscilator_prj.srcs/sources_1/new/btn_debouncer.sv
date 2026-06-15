//--------------------------------------------------------------------------------
// Company:       CSD Lab6
// Engineer:      Ring Oscillator Project
//
// Create Date:   2026-06-06
// Design Name:   btn_debouncer
// Module Name:   btn_debouncer
// Project Name:  ring_oscilator_prj
// Target Devices: Xilinx Arty S7-50 (XC7S50-CSGA324)
// Tool Versions: Vivado 2018.3
// Description:   Synchroniczny debouncer przycisku — filtruje drgania mechaniczne
//                zanim sygnał trafi do logiki wyboru częstotliwości (V2).
//
// Dependencies:  none
//
// Revision:
// Revision 0.01 - File Created
//--------------------------------------------------------------------------------
`timescale 1ns / 1ps

module btn_debouncer #(
    parameter int CLK_HZ           = 12_000_000,
    parameter int DEBOUNCE_MS      = 20,
    parameter int ACTIVE_HIGH      = 1
) (
    input  logic clk,
    input  logic rst_n,
    input  logic btn_raw,
    output logic btn_stable,
    output logic btn_posedge
);

  localparam int CNT_MAX = (CLK_HZ / 1000) * DEBOUNCE_MS;

  logic        btn_sync_1, btn_sync_2;
  logic        btn_eff;
  logic [31:0] cnt;
  logic        stable_q, stable_prev;

  assign btn_eff = ACTIVE_HIGH ? btn_raw : ~btn_raw;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      btn_sync_1 <= 1'b0;
      btn_sync_2 <= 1'b0;
    end else begin
      btn_sync_1 <= btn_eff;
      btn_sync_2 <= btn_sync_1;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      cnt       <= '0;
      stable_q  <= 1'b0;
    end else if (btn_sync_2 != stable_q) begin
      if (cnt >= CNT_MAX[31:0]) begin
        stable_q <= btn_sync_2;
        cnt      <= '0;
      end else begin
        cnt <= cnt + 32'd1;
      end
    end else begin
      cnt <= '0;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) stable_prev <= 1'b0;
    else        stable_prev <= stable_q;
  end

  assign btn_stable  = stable_q;
  assign btn_posedge = stable_q & ~stable_prev;

endmodule : btn_debouncer
