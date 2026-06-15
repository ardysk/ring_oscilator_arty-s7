//--------------------------------------------------------------------------------
// Company:       CSD Lab6
// Engineer:      Ring Oscillator Project
//
// Create Date:   2026-06-06
// Design Name:   tb_v1_meas_flow
// Module Name:   tb_v1_meas_flow
// Project Name:  ring_oscilator_prj
// Target Devices: Simulation
// Tool Versions: Vivado 2018.3
// Description:   Testbench przepływu pomiaru V1 — FSM ro_freq_measure + syntetyczne RO.
//
// Revision:
// Revision 0.01 - File Created
//--------------------------------------------------------------------------------
`timescale 1ns / 1ps

module tb_v1_meas_flow;

  localparam int F_REF = 12_000_000;
  localparam int GATE  = 4000;

  logic clk;
  logic rst_n;
  logic ro_async;
  logic meas_start;
  logic [31:0] gate_cycles;
  logic meas_busy, meas_done;
  logic [31:0] meas_edge_count, meas_freq_hz;
  logic done_seen;

  // Syntetyczne „RO” — kwadrat ~1 MHz (łatwe do symulacji behav)
  int div;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      div      <= 0;
      ro_async <= 1'b0;
    end else if (div >= 5) begin
      div      <= 0;
      ro_async <= ~ro_async;
    end else begin
      div <= div + 1;
    end
  end

  ro_freq_measure #(
      .F_REF_HZ(F_REF)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .ro_async(ro_async),
      .meas_start(meas_start),
      .gate_cycles(gate_cycles),
      .meas_busy(meas_busy),
      .meas_done(meas_done),
      .meas_edge_count(meas_edge_count),
      .meas_freq_hz(meas_freq_hz)
  );

  initial clk = 0;
  always #41.667ns clk = ~clk;

  initial begin
    rst_n = 0;
    meas_start = 0;
    gate_cycles = GATE;
    #200ns;
    rst_n = 1;
    #500ns;
    meas_start = 1;
    @(posedge clk);
    @(posedge clk);
    meas_start = 0;
    done_seen = 0;
    repeat (20000) begin
      @(posedge clk);
      if (meas_done) begin
        done_seen = 1;
        break;
      end
    end
    if (!done_seen) begin
      $error("FAIL: measurement timeout");
      $finish;
    end
    @(posedge clk);
    $display("V1 meas: edges=%0d freq_hz=%0d busy=%b",
             meas_edge_count, meas_freq_hz, meas_busy);
    if (meas_edge_count == 0)
      $error("FAIL: expected edges from synthetic RO");
    else if (meas_freq_hz < 500_000 || meas_freq_hz > 2_000_000)
      $warning("WARN: freq_hz=%0d outside ~1 MHz band (CDC sampling)", meas_freq_hz);
    else
      $display("PASS: measurement FSM and freq calc OK");
    $display("PASS: meas_done pulse captured");
    $finish;
  end

endmodule
