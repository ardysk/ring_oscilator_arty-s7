// Testbench ro_top_arty — 12 MHz, reset na btn[3]; pomiar: btn[0]; surowy tap: SW[3:1]=111.
// Zob. tb_ro_top_zed dla dokumentacji krótkiej bramki pomiaru.
`timescale 1ns / 1ps

module tb_ro_top_arty;

  localparam int SHORT_GATE_CYCLES = 32'd4_000;
  bit            gate_shortened;

  logic       clk_12mhz;
  logic [3:0] btn;
  logic [3:0] sw;
  wire  [3:0] led;
  wire        ro_scope;

  ro_top_arty dut (
      .clk_12mhz(clk_12mhz),
      .btn      (btn),
      .sw       (sw),
      .led      (led),
      .ro_scope (ro_scope)
  );

  initial clk_12mhz = 1'b0;
  // 12 MHz ≈ 83,33 ns okres → ~41,67 ns pół — przybliżenie wystarczy do TB funkcjonalnego.
  always #41.667ns clk_12mhz = ~clk_12mhz;

  task automatic pulse_meas_start;
    begin
      @(posedge clk_12mhz);
      btn[0] = 1'b1;  // przyciski: wciśnięty = HIGH
      @(posedge clk_12mhz);
      btn[0] = 1'b0;
    end
  endtask

  task automatic wait_meas_done;
    begin
      wait (dut.meas_done === 1'b1);
      @(posedge clk_12mhz);
    end
  endtask

  task automatic apply_short_gate_if_fast;
    begin
      if (!$test$plusargs("full_gate")) begin
        force dut.meas_gate_cycles = SHORT_GATE_CYCLES;
        gate_shortened = 1'b1;
        $display(
            "tb_ro_top_arty: short gate: forced meas_gate_cycles = %0d (+full_gate = ~150000 @ 12MHz)",
            SHORT_GATE_CYCLES);
      end
    end
  endtask

  int cA, cB;

  initial begin
    $display("TB_REV tb_ro_top_arty v1 (Arty clock ~12 MHz)");
    sw             = 4'h0;
    gate_shortened = 1'b0;
    cA             = 0;
    cB             = 0;
    btn            = 4'b1000;

    $display("tb_ro_top_arty: phase A — zwolnienie resetu (~btn[3])");
    repeat (20) @(posedge clk_12mhz);
    btn[3] = 1'b0;
    repeat (10) @(posedge clk_12mhz);

    sw  = 4'b1110;  // RAW (SW[3:1]=111) + wyłączenie RO (SW[0]=0)
    btn = 4'b0000;
    repeat (80) @(posedge clk_12mhz);
    $display("tb_ro_top_arty: phase B — RAW + RO wyłączone — brak stale Z/X na JA");
    if (ro_scope === 1'bz)
      $fatal(1, "ro_scope stale Z przy RAW+ RO off");

    sw = 4'b0001;  // 1 MHz synth na JA + włączenie RO
    repeat (50) @(posedge clk_12mhz);

    $display("tb_ro_top_arty: phase C — pierwszy pomiar (tune=0)");
    apply_short_gate_if_fast();
    pulse_meas_start();
    wait_meas_done();
    cA = int'(led);
    $display("tb_ro_top_arty: meas A led[3:0]=%0h", cA);

    // Największe strojenie z dwóch bitów tune: tune10={5'h0,btn[2:1],3'h0}; btn wyższe przy pomiarze
    sw[0] = 1'b0;
    repeat (20) @(posedge clk_12mhz);
    sw  = 4'b0111;
    btn = 4'b0110;
    repeat (50) @(posedge clk_12mhz);

    apply_short_gate_if_fast();
    pulse_meas_start();
    wait_meas_done();
    cB = int'(led);
    $display("tb_ro_top_arty: meas B (tune=max z btn[2:1]=11) led[3:0]=%0h", cB);

    if (gate_shortened) release dut.meas_gate_cycles;
    $display("tb_ro_top_arty: done; ro_scope = %b", ro_scope);
    $finish;
  end

endmodule : tb_ro_top_arty
