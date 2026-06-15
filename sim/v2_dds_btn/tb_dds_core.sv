//--------------------------------------------------------------------------------
// Company:       CSD Lab6
// Engineer:      Ring Oscillator Project
//
// Create Date:   2026-06-06
// Design Name:   tb_dds_core
// Module Name:   tb_dds_core
// Project Name:  ring_oscilator_prj
// Target Devices: Simulation
// Tool Versions: Vivado 2018.3
// Description:   Testbench DDS — sprawdza okres przy zadanej częstotliwości.
//
// Revision:
// Revision 0.01 - File Created
//--------------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_dds_core;

  logic clk, rst_n, en, dds_out;
  logic [31:0] freq_hz, phase_out;

  localparam int F_TEST = 1_000_000;

  dds_core #(
      .F_CLK_HZ(12_000_000)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .en(en),
      .freq_hz(freq_hz),
      .dds_out(dds_out),
      .phase_out(phase_out)
  );

  initial clk = 0;
  always #41.667ns clk = ~clk;

  time t_rise, t_prev;
  int edges;
  real period_ns, freq_meas;

  initial begin
    rst_n = 0;
    en = 0;
    freq_hz = F_TEST;
    edges = 0;
    t_prev = 0;
    #500ns;
    rst_n = 1;
    en = 1;
    #8000000ns;
    if (edges >= 2) begin
      period_ns = (t_rise - t_prev) / 1.0ns;
      freq_meas = 1.0e9 / period_ns;
      $display("DDS: edges=%0d period=%.1f ns f_meas=%.0f Hz", edges, period_ns, freq_meas);
      if (freq_meas > 0.8e6 && freq_meas < 1.2e6)
        $display("PASS: ~1 MHz");
      else
        $error("FAIL: frequency out of expected range (%.0f Hz)", freq_meas);
    end else begin
      $error("FAIL: not enough DDS edges (%0d)", edges);
    end
    $finish;
  end

  always @(posedge dds_out) begin
    if (edges > 0) t_prev = t_rise;
    t_rise = $time;
    edges++;
  end

endmodule
