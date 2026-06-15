// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Block-design wrapper for the experimental V2 UART plus TFT system image.
// Archived netlist shell; the repository default programs V1 mb_ro_system_wrapper instead.
// Kept for reference when rebuilding the TFT branch locally.

`timescale 1ns / 1ps

module mb_ro_system_v2_wrapper (
    input  wire [3:0] btn,
    input  wire       clk_12mhz,
    output wire [3:0] led,
    output wire       ro_scope,
    output wire       ro_scope_ring,
    input  wire [3:0] sw,
    input  wire       uart_usb_rxd,
    output wire       uart_usb_txd,
    output wire       tft_sck,
    output wire       tft_mosi,
    output wire       tft_cs_n,
    output wire       tft_dc,
    output wire       tft_rst_n
);

  wire rst_n;
  assign rst_n = ~btn[3];

  wire [31:0] tft_freq_hz;
  reg  [31:0] tft_freq_lat;
  wire        tft_meas_done;
  wire        tft_meas_busy;
  reg         tft_meas_arm;

  mb_ro_system_wrapper u_sys (
      .btn           (btn),
      .clk_12mhz     (clk_12mhz),
      .led           (led),
      .ro_scope      (ro_scope),
      .ro_scope_ring (ro_scope_ring),
      .sw            (sw),
      .uart_usb_rxd  (uart_usb_rxd),
      .uart_usb_txd  (uart_usb_txd)
  );

  always @(posedge clk_12mhz or negedge rst_n) begin
    if (!rst_n)
      tft_meas_arm <= 1'b1;
    else if (tft_meas_done)
      tft_meas_arm <= 1'b1;
    else if (tft_meas_busy)
      tft_meas_arm <= 1'b0;
  end

  ro_freq_measure #(
      .F_REF_HZ(12_000_000)
  ) u_tft_meas (
      .clk            (clk_12mhz),
      .rst_n          (rst_n),
      .ro_async       (ro_scope),
      .meas_start     (tft_meas_arm),
      .gate_cycles    (32'd60_000),
      .meas_busy      (tft_meas_busy),
      .meas_done      (tft_meas_done),
      .meas_edge_count(),
      .meas_freq_hz   (tft_freq_hz)
  );

  always @(posedge clk_12mhz or negedge rst_n) begin
    if (!rst_n)
      tft_freq_lat <= 32'd0;
    else if (tft_meas_done)
      tft_freq_lat <= tft_freq_hz;
  end

  gc9a01_driver #(
      .REFRESH_CYCLES(6_000_000)
  ) u_tft (
      .clk        (clk_12mhz),
      .rst_n      (rst_n),
      .freq_hz    (tft_freq_lat),
      .target_mhz (9'd0),
      .tft_sck    (tft_sck),
      .tft_mosi   (tft_mosi),
      .tft_cs_n   (tft_cs_n),
      .tft_dc     (tft_dc),
      .tft_rst_n  (tft_rst_n),
      .busy       ()
  );

endmodule
