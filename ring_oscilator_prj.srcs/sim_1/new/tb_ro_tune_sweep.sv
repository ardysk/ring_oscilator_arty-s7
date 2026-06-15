// Symulacja: przemiatanie kodów ro_tune_sel na surowym `ro_top`, pomiary z `ro_freq_measure`,
// szacunkowe_f_MHz = meas_edge_count * f_clk / (2 * meas_gate_cycles).
//
// UWAGI (ważne):
// — Pierścień RTL to ta sama logika co po syntezie (bez opóźnień #): w XSim `ro_out` może zostać X/Z
//   (pętla zero‑delay). Pomiar (`ro_freq_measure`) i tabela mają sens przy stabilnym „logicznym” przebiegu —
//   w razie X w całym przemiataj porównaj wynik z syntezą / post‑synth sim albo włącz transport delay w ustawieniach projektu symulacji.
// — Domyślnie przemiata 64 kodów (0..63); zmiana: początek `initial` (sweep_lim) lub w XSim/elab opcja typu `+sweep=256`.
//
// Uruchomienie (jak run_sim.tcl, ale zmienia Top):
//   source scripts/run_sim_tune_sweep.tcl

`timescale 1ns / 1ps

module tb_ro_tune_sweep;

  localparam int   N_tune        = 10;
  localparam int   GATE_CY       = 32'd6000;
  localparam realtime F_CLK_MHZ  = 100.0;  // zgodne z clk w TB: periodycznie #5 ns => 100 MHz

  logic                      clk;
  logic                      rst_n;
  logic                      ro_en;
  logic [N_tune-1:0]         ro_tune_sel;
  logic                      meas_start;
  logic             [31:0] meas_gate_cycles;
  logic                      ro_out;
  logic                      meas_busy, meas_done;
  logic             [31:0] meas_edge_count;
  logic             [31:0] meas_freq_hz;

  int unsigned sweep_lim;
  int unsigned c;

  ro_top #(
      .RO_BANKS      (1),
      .RO_NUM_TUNE_BITS(N_tune)
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

  always #5ns clk = ~clk;

  task automatic pulse_start;
    begin
      @(posedge clk);
      meas_start <= 1'b1;
      @(posedge clk);
      meas_start <= 1'b0;
    end
  endtask

  task automatic wait_done;
    begin
      wait (meas_done === 1'b1);
      @(posedge clk);
    end
  endtask

  function automatic real mhz_estimate(input int unsigned edges);
    // f_ro ~= edges / (2 * T_gate) , T_gate = GATE_CY / f_clk
    mhz_estimate = (edges * F_CLK_MHZ) / (2.0 * real'(GATE_CY));
  endfunction

  initial begin
    sweep_lim = 64;
    if (!$value$plusargs("sweep=%d", sweep_lim)) sweep_lim = 64;
    if (sweep_lim < 1) sweep_lim = 1;
    if (sweep_lim > (2 ** N_tune)) sweep_lim = 2 ** N_tune;

    $display("");
    $display(
        "=== tb_ro_tune_sweep: N_tune=%0d, GATE_CY=%0d, f_clk_sim=%g MHz ===",
            N_tune, GATE_CY, F_CLK_MHZ);
    $display(
        "# f_est [MHz] ~= edges * %g / (2 * %0d); bramka = GATE_CY Cykli zegara synchr.",
            F_CLK_MHZ, GATE_CY);
    $display("---");
    $display("%6s %10s %12s %14s  %s", "kod.dec", "kod(hex)", "meas_edges", "f_est_sim_MHz",
        "(tylko sim / porownaj wzglednie)");
    $display(" --------------------------------------------------------------------------------");

    clk              = 1'b0;
    rst_n            = 1'b0;
    ro_en            = 1'b0;
    ro_tune_sel      = '0;
    meas_start       = 1'b0;
    meas_gate_cycles = GATE_CY;

    #(20 * 10ns);
    rst_n = 1'b1;
    #(10 * 10ns);

    for (c = 0; c < sweep_lim; c++) begin
      ro_en             = 1'b0;
      @(posedge clk);
      ro_tune_sel       = N_tune'(unsigned'(c));

      @(posedge clk);
      ro_en = 1'b1;
      repeat (400) @(posedge clk);

      if (ro_out !== 1'b0 && ro_out !== 1'b1)
        $display("NOTICE kod=%0d — ro_out jeszcze X/Z po settle (moze zajsc w wybranych kodach/sim); licznik dalej leci.", c);

      pulse_start();
      wait_done();

      begin
        int unsigned edges;
        real         mhz;
        edges = unsigned'(meas_edge_count);
        mhz   = mhz_estimate(edges);
        $display("%6d %10x %12d        %0.3f", c, c, edges, mhz);
      end
      @(posedge clk);
    end

    $display("=== tb_ro_tune_sweep: koniec (sweep_lim=%0d) ===", sweep_lim);
    $finish;
  end

endmodule : tb_ro_tune_sweep
