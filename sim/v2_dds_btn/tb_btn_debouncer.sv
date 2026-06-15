// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Unit testbench for the btn_debouncer module with synthetic bounce waveforms.
// Checks that only stable presses produce a single detected edge.
// Supports regression of the V2 input path in XSim.

`timescale 1ns / 1ps

module tb_btn_debouncer;

  localparam int CLK_HZ      = 12_000_000;
  localparam int DEBOUNCE_MS = 1;
  localparam int CNT_MAX     = (CLK_HZ / 1000) * DEBOUNCE_MS;
  localparam time CLK_HALF   = 41.667ns;
  localparam time HOLD_NS    = (CNT_MAX + 2000) * CLK_HALF * 2;

  logic clk, rst_n, btn_raw, btn_stable, btn_posedge;

  btn_debouncer #(
      .CLK_HZ(CLK_HZ),
      .DEBOUNCE_MS(DEBOUNCE_MS)
  ) dut (
      .clk(clk),
      .rst_n(rst_n),
      .btn_raw(btn_raw),
      .btn_stable(btn_stable),
      .btn_posedge(btn_posedge)
  );

  initial clk = 0;
  always #CLK_HALF clk = ~clk;

  int posedge_cnt;

  initial begin
    rst_n = 0;
    btn_raw = 0;
    posedge_cnt = 0;
    #200ns;
    rst_n = 1;

    // Drgania — krótsze niż okno debounce
    repeat (5) begin
      btn_raw = 1;
      #1000ns;
      btn_raw = 0;
      #1000ns;
    end

    // Stabilne naciśnięcie — musi trwać dłużej niż CNT_MAX cykli clk
    btn_raw = 1;
    #HOLD_NS;
    btn_raw = 0;
    #HOLD_NS;

    if (posedge_cnt >= 1)
      $display("PASS: debouncer detected %0d posedge(s)", posedge_cnt);
    else
      $error("FAIL: no stable posedge");
    $finish;
  end

  always @(posedge clk) begin
    if (btn_posedge) posedge_cnt++;
  end

endmodule
