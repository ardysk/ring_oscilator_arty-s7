//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.3 (win64) Build 2405991 Thu Dec  6 23:38:27 MST 2018
//Date        : Tue Jun  9 15:27:48 2026
//Host        : DESKTOP-6DMTGNH running 64-bit major release  (build 9200)
//Command     : generate_target mb_ro_system_wrapper.bd
//Design      : mb_ro_system_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module mb_ro_system_wrapper
   (btn,
    clk_12mhz,
    led,
    ro_scope,
    ro_scope_ring,
    sw,
    uart_usb_rxd,
    uart_usb_txd);
  input [3:0]btn;
  input clk_12mhz;
  output [3:0]led;
  output ro_scope;
  output ro_scope_ring;
  input [3:0]sw;
  input uart_usb_rxd;
  output uart_usb_txd;

  wire [3:0]btn;
  wire clk_12mhz;
  wire [3:0]led;
  wire ro_scope;
  wire ro_scope_ring;
  wire [3:0]sw;
  wire uart_usb_rxd;
  wire uart_usb_txd;

  mb_ro_system mb_ro_system_i
       (.btn(btn),
        .clk_12mhz(clk_12mhz),
        .led(led),
        .ro_scope(ro_scope),
        .ro_scope_ring(ro_scope_ring),
        .sw(sw),
        .uart_usb_rxd(uart_usb_rxd),
        .uart_usb_txd(uart_usb_txd));
endmodule
