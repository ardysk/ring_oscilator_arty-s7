// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Generic behavioral testbench for legacy ro_top connectivity and measurement.
// Exercises ring enable, bank mux, and basic frequency gate completion.
// Retained for gate-level and RTL regression in the Vivado sim_1 fileset.

`timescale 1ns / 1ps

module tb_ro_top;

  logic        clk;
  logic        rst_n;
  logic        ro_en;
  logic        meas_start;
  logic [31:0] meas_gate_cycles;
  logic [3:0]  ro_tune_sel;
  logic        ro_out;
  logic        meas_busy;
  logic        meas_done;
  logic [31:0] meas_edge_count;
  logic [31:0] meas_freq_hz;

  int          c_fast, c_slow;

  ro_top #(
      .RO_BANKS           (1),
      .RO_NUM_TUNE_BITS   (4),
      .RO_NUM_TAIL_INVERTERS(2)
  ) dut (
      .clk              (clk),
      .rst_n            (rst_n),
      .ro_en            (ro_en),
      .ro_tune_sel      (ro_tune_sel),
      .ro_bank_sel      (1'b0),
      .meas_start       (meas_start),
      .meas_gate_cycles (meas_gate_cycles),
      .ro_out           (ro_out),
      .meas_busy        (meas_busy),
      .meas_done        (meas_done),
      .meas_edge_count  (meas_edge_count),
      .meas_freq_hz     (meas_freq_hz)
  );

  initial clk = 1'b0;
  always #5ns clk = ~clk;

  task automatic run_measure;
    begin
      meas_start = 1'b1;
      @(posedge clk);
      meas_start = 1'b0;
      wait (meas_done);
      @(posedge clk);
    end
  endtask

  initial begin
    rst_n            = 1'b0;
    ro_en            = 1'b0;
    ro_tune_sel      = 4'b0000;
    meas_start       = 1'b0;
    meas_gate_cycles = 32'd500;

    repeat (8) @(posedge clk);
    rst_n = 1'b1;
    repeat (4) @(posedge clk);

    if (ro_out === 1'bx || ro_out === 1'bz)
      $fatal(1, "ro_out X/Z przy wylaczonym RO");

    ro_en = 1'b1;
    repeat (50) @(posedge clk);

    if (ro_out === 1'bx || ro_out === 1'bz)
      $fatal(1, "ro_out X/Z — ring / tune chain");

    // Pomiar 1: bypass wszystkich segmentów (najszybciej)
    ro_tune_sel = 4'b0000;
    repeat (20) @(posedge clk);
    run_measure();
    c_fast = meas_edge_count;
    $display("tune=0x0  meas_edge_count=%0d", c_fast);

    // Zmiana strojenia przy wylaczonym pierścieniu (mniej glitchy)
    ro_en = 1'b0;
    repeat (10) @(posedge clk);
    ro_tune_sel = 4'b1111;
    repeat (10) @(posedge clk);
    ro_en = 1'b1;
    repeat (50) @(posedge clk);

    run_measure();
    c_slow = meas_edge_count;
    $display("tune=0xF  meas_edge_count=%0d", c_slow);

    if (c_slow >= c_fast)
      $display("NOTE: oczekiwano c_slow < c_fast (wolniejszy RO -> mniej zboczy); sprawdz symulacje");
    else
      $display("tb_ro_top: strojenie OK — wiecej opoznien (lower f) => mniej zboczy: %0d < %0d", c_slow, c_fast);

    $finish;
  end

endmodule : tb_ro_top
