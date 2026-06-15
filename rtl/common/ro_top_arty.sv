`timescale 1ns / 1ps

module ro_top_arty #(
    parameter int RO_NUM_TUNE_BITS           = 10,
    parameter int RO_NUM_TAIL_INVERTERS      = 2,
    parameter int RO_BANK_CNT                = 8,
    parameter int DIV_CNT_W                  = 16,
    parameter int TARGET_MHZ_MAX             = 511,
    parameter int TARGET_INIT_MHZ            = 10,
    parameter int DIV_BYPASS_ABOVE_MHZ       = 60,  // z target powyżej progu lub SW[3] wyłącznie „tryb bez podziału przez half_edges”.
    parameter [31:0] MEAS_GATE_CYCLES_DEFAULT = 32'd60_000,
    parameter int unsigned F_RO_EST_MHZ_BANK0 = 48,
    parameter int unsigned F_RO_EST_MHZ_BANK7 = 185
) (
    input  logic       clk_12mhz,
    input  logic [3:0] btn,
    input  logic [3:0] sw,
    output logic [3:0] led,
    output logic       ro_scope,       // JA pin 1 (L17) — dzielnik + SW[3]/bypass
    output logic       ro_scope_ring   // JA pin 2 (L18) — zawsze zsynchronizowany tap pierścienia
);

  localparam int BANK_SEL_W = (RO_BANK_CNT <= 1) ? 1 : $clog2(RO_BANK_CNT);

  logic rst_n;
  logic ro_en;
  logic meas_start;
  (* DONT_TOUCH = "yes" *)
  logic [31:0] meas_gate_cycles;
  logic        ro_out;

  logic        meas_busy;
  logic        meas_done;
  logic [31:0] meas_edge_count;
  logic [31:0] meas_freq_hz;
  logic [3:0]  led_lat;

  assign rst_n            = ~btn[3];
  assign ro_en            = sw[0];
  assign meas_start       = btn[2];
  assign meas_gate_cycles = MEAS_GATE_CYCLES_DEFAULT;

  generate
    if (RO_NUM_TUNE_BITS != 10) begin : gw
      initial $fatal(1, "ro_top_arty: RO_NUM_TUNE_BITS musi być 10.");
    end
    if (RO_BANK_CNT != 8) begin : gbcnt
      initial $fatal(1, "ro_top_arty: obecnie skonfiguruj dokładnie 8 banków pierścienia.");
    end
  endgenerate

  logic [RO_BANK_CNT * RO_NUM_TUNE_BITS-1:0] ro_tune_bus;

  ro_bank_tune_pack #(
      .NUM_BANKS    (RO_BANK_CNT),
      .NUM_TUNE_BITS(RO_NUM_TUNE_BITS)
  ) u_tune_pack (
      .ro_tune_bus(ro_tune_bus)
  );

  localparam logic [17:0] DB_CYCLES = 18'd150_000;

  logic       stable_btn0;
  logic       stable_btn1;
  logic       stable_btn0_d;
  logic       stable_btn1_d;
  logic [17:0] ctr0_deb;
  logic [17:0] ctr1_deb;

  always_ff @(posedge clk_12mhz or negedge rst_n) begin
    if (!rst_n) begin
      stable_btn0 <= 1'b0;
      stable_btn1 <= 1'b0;
      ctr0_deb <= '0;
      ctr1_deb <= '0;
    end else begin
      if (btn[0] != stable_btn0) begin
        if (ctr0_deb >= DB_CYCLES - 18'd1) begin
          stable_btn0 <= btn[0];
          ctr0_deb <= '0;
        end else ctr0_deb <= ctr0_deb + 18'd1;
      end else ctr0_deb <= '0;

      if (btn[1] != stable_btn1) begin
        if (ctr1_deb >= DB_CYCLES - 18'd1) begin
          stable_btn1 <= btn[1];
          ctr1_deb <= '0;
        end else ctr1_deb <= ctr1_deb + 18'd1;
      end else ctr1_deb <= '0;
    end
  end

  always_ff @(posedge clk_12mhz or negedge rst_n) begin
    if (!rst_n) begin
      stable_btn0_d <= 1'b0;
      stable_btn1_d <= 1'b0;
    end else begin
      stable_btn0_d <= stable_btn0;
      stable_btn1_d <= stable_btn1;
    end
  end

  wire minus_event = stable_btn0 & ~stable_btn0_d;
  wire plus_event  = stable_btn1 & ~stable_btn1_d;

  logic [8:0] target_mhz;
  always_ff @(posedge clk_12mhz or negedge rst_n) begin
    if (!rst_n)
      target_mhz <= TARGET_INIT_MHZ > TARGET_MHZ_MAX ? 9'd1 :
          9'(TARGET_INIT_MHZ);
    else begin
      if (minus_event && target_mhz > 9'd1) target_mhz <= target_mhz - 9'd1;
      if (plus_event && target_mhz < 9'(TARGET_MHZ_MAX)) target_mhz <= target_mhz + 9'd1;
    end
  end

  logic [     BANK_SEL_W-1:0] ro_bank_sel;
  logic [     DIV_CNT_W-1:0] half_edges_eff;
  logic                      div_bypass;
  logic [RO_BANK_CNT * DIV_CNT_W-1:0] half_edges_bus;
  logic [RO_BANK_CNT-1:0]             div_bypass_bus;
  logic [8:0]                         f_pred_unused;

  ro_target_map #(
      .BANK_SEL_W(BANK_SEL_W),
      .RO_BANKS  (RO_BANK_CNT),
      .DIV_CNT_W (DIV_CNT_W)
  ) u_target (
      .target_mhz     (target_mhz),
      .bank_sel       (ro_bank_sel),
      .half_edges_bus (half_edges_bus),
      .div_bypass_bus (div_bypass_bus),
      .f_pred_mhz     (f_pred_unused)
  );

  assign half_edges_eff = half_edges_bus[ro_bank_sel * DIV_CNT_W+:DIV_CNT_W];
  assign div_bypass     = div_bypass_bus[ro_bank_sel];

  wire div_bypass_eff = (sw[3] == 1'b1) ? 1'b1 : div_bypass;

  (* keep_hierarchy = "yes" *)
  ro_top #(
      .RO_BANKS               (RO_BANK_CNT),
      .RO_NUM_TUNE_BITS      (RO_NUM_TUNE_BITS),
      .RO_NUM_TAIL_INVERTERS (RO_NUM_TAIL_INVERTERS)
  ) u_core (
      .clk              (clk_12mhz),
      .rst_n            (rst_n),
      .ro_en            (ro_en),
      .ro_tune_sel      (ro_tune_bus),
      .ro_bank_sel      (ro_bank_sel),
      .meas_start       (meas_start),
      .meas_gate_cycles (meas_gate_cycles),
      .ro_out           (ro_out),
      .meas_busy        (meas_busy),
      .meas_done        (meas_done),
      .meas_edge_count  (meas_edge_count),
      .meas_freq_hz     (meas_freq_hz)
  );

  logic ro_scope_muxed;

  ring_prog_toggle_div #(
      .CNT_W(DIV_CNT_W)
  ) u_hz_scope_div (
      .rst_n       (rst_n),
      .ro_clk      (ro_out),
      .bypass      (div_bypass_eff),
      .half_edges  (DIV_CNT_W'(half_edges_eff)),
      .div_out     (ro_scope_muxed)
  );

  arty_scope_freq_mux u_scope (
      .clk_in_12mhz (clk_12mhz),
      .rst_n        (rst_n),
      .raw_ring_sig (ro_scope_muxed),
      .scope_out    (ro_scope),
      .pll_locked   ()
  );

  arty_scope_freq_mux u_scope_ring (
      .clk_in_12mhz (clk_12mhz),
      .rst_n        (rst_n),
      .raw_ring_sig (ro_out),
      .scope_out    (ro_scope_ring),
      .pll_locked   ()
  );

  always_ff @(posedge clk_12mhz or negedge rst_n) begin
    if (!rst_n) led_lat <= '0;
    else if (meas_done) led_lat <= meas_freq_hz[3:0];
  end

  assign led = meas_busy ? 4'hA : target_mhz[3:0];

endmodule : ro_top_arty
