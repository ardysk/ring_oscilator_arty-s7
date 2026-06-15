// Testbench for ro_top_zed — drives ZedBoard-mapped ports (matches timing netlist top).
// Post-implementation timing: use this TB, not tb_ro_top (netlist `ro_top` ports are not RTL).
//
// Post-impl timing netlist: `dut.meas_gate_cycles` must exist for `force` below — in `ro_top_zed.sv`
// the net has (* DONT_TOUCH *); after changing that, re-run **impl_1** so Vivado regenerates the sim netlist.
//
// Short sim: `force` krótki licznik na dut.meas_gate_cycles (RTL ma stałe MEAS_GATE_CYCLES_DEFAULT).
// Stary układ {sw,sw,sw,sw} sprzęgał strojenie z bramką; teraz meas_start/ro_en są osobno od meas_gate.
`timescale 1ns / 1ps

module tb_ro_top_zed;

  // Post-impl timing: each clk evaluates the full gate-level+SDF model — keep this *small*.
  // (Board RTL uses MEAS_GATE_CYCLES_DEFAULT ~1.25e6; here we only sanity-check FSM + done.)
  localparam int SHORT_GATE_CYCLES = 32'd4_000;
  bit            gate_shortened;

  logic       clk_100mhz;
  logic       btnc;
  logic       btnu, btnr, btnl, btnd;
  logic [7:0] sw;
  wire  [7:0] led;
  wire        ro_scope;

  ro_top_zed dut (
      .clk_100mhz(clk_100mhz),
      .btnc      (btnc),
      .btnu      (btnu),
      .btnr      (btnr),
      .btnl      (btnl),
      .btnd      (btnd),
      .sw        (sw),
      .led       (led),
      .ro_scope  (ro_scope)
  );

  initial clk_100mhz = 1'b0;
  always #5ns clk_100mhz = ~clk_100mhz;

  task automatic pulse_meas_start;
    begin
      @(posedge clk_100mhz);
      sw[1] = 1'b1;
      @(posedge clk_100mhz);
      sw[1] = 1'b0;
    end
  endtask

  task automatic wait_meas_done;
    begin
      // meas_done is often one short cycle on the *routed* clock (IBUF/BUFG). Sampling only
      // @ posedge tb clk_100mhz can miss the pulse in post-impl timing sim -> endless loop.
      wait (dut.meas_done === 1'b1);
      @(posedge clk_100mhz);
    end
  endtask

  task automatic apply_short_gate_if_fast;
    begin
      if (!$test$plusargs("full_gate")) begin
        force dut.meas_gate_cycles = SHORT_GATE_CYCLES;
        gate_shortened = 1'b1;
        $display("tb_ro_top_zed: short gate: forced meas_gate_cycles = %0d (use +full_gate for RTL ~1.25e6)",
            SHORT_GATE_CYCLES);
      end
    end
  endtask

  int cA, cB;

  initial begin
    // If log still shows "200000" or old rev, Vivado is using stale xelab cache or a different project copy.
    $display(
        "TB_REV tb_ro_top_zed v6.3 (+ short_gate before meas A; SHORT_GATE_CYCLES=%0d)",
        SHORT_GATE_CYCLES);
    sw             = 8'h00;
    btnc           = 1'b0;
    btnu           = 1'b0;
    btnr           = 1'b0;
    btnl           = 1'b0;
    btnd           = 1'b0;
    cA             = 0;
    cB             = 0;
    gate_shortened = 1'b0;

    $display("tb_ro_top_zed: phase A — release reset (wait 20 clk)");
    repeat (20) @(posedge clk_100mhz);
    btnc = 1'b1;
    repeat (10) @(posedge clk_100mhz);

    $display("tb_ro_top_zed: phase B — check ro_scope with RO off (expect 0, not X/Z)");
    if (ro_scope === 1'bz || ro_scope === 1'bx)
      $fatal(1, "ro_scope X/Z while RO off (btnc/rst) - check delays / en");

    // Enable RO (tune=0 na sw[7:2]); bez short force pomiar używa MEAS_GATE_CYCLES_DEFAULT z RTL.
    sw = 8'h01;
    repeat (50) @(posedge clk_100mhz);

    $display("tb_ro_top_zed: phase C — RO on, wait until ro_scope leaves X/Z (RTL/gates delay)");
    begin
      int unsigned waits;
      waits = 0;
      while ((ro_scope === 1'bz || ro_scope === 1'bx) && waits < 50000) begin
        @(posedge clk_100mhz);
        waits++;
      end
      if (ro_scope === 1'bz || ro_scope === 1'bx)
        // Post-Synthesis Functional = LUT primitives with no unit delays → combinational-loop
        // RO tap often sticks X/Z; still useful to exercise meas FSM via clk/timer.
        $warning(
          "tb_ro_top_zed: ro_scope unresolved after long wait — skipping strict RO check (%0d TB clk edges). Typical for Post-Synth *Functional*. Use Behavioral RTL or Timing sim for RO waveform.",
              waits);
    end

    $display("tb_ro_top_zed: phase D — first measure");
    apply_short_gate_if_fast();
    pulse_meas_start();
    wait_meas_done();
    cA = int'(led);
    $display("tb_ro_top_zed: meas A (sw=0x01, tune=0) led[7:0]=%0d", cA);

    // Drugi pomiar: maksymalnie 10-bit tune = {BTN, sw[7:2]} → wszystkie = 1 przy wciśniętych klawiszach kierunku
    sw[0] = 1'b0;
    repeat (20) @(posedge clk_100mhz);
    sw   = 8'hFD;  // en=1, sw[7:2]=6'h3F
    btnu = 1'b1;
    btnr = 1'b1;
    btnl = 1'b1;
    btnd = 1'b1;
    repeat (50) @(posedge clk_100mhz);

    apply_short_gate_if_fast();
    pulse_meas_start();
    wait_meas_done();
    cB = int'(led);
    $display("tb_ro_top_zed: meas B (sw=8'hFD tune_lsb, btnU..D=1111 → tune10=max) led[7:0]=%0d", cB);
    if ($test$plusargs("full_gate"))
      $display("NOTE: full_gate — każdy pomiar ~1_250_000 cykli zegara (wolno w post-impl timing).");
    else
      $display("NOTE: short gate for sim; meas_gate forced to %0d cycles.", SHORT_GATE_CYCLES);

    if (gate_shortened) release dut.meas_gate_cycles;

    $display("tb_ro_top_zed: done; ro_scope last = %b", ro_scope);
    $finish;
  end

endmodule : tb_ro_top_zed
