`timescale 1ns / 1ps

module ro_top #(
    parameter int RO_BANKS              = 1,
    parameter int RO_NUM_TUNE_BITS       = 12,
    parameter int RO_NUM_TAIL_INVERTERS = 2,
    parameter bit MEAS_ENABLE           = 1'b1
) (
    input  logic                                                    clk,
    input  logic                                                    rst_n,
    input  logic                                                    ro_en,
    input  logic [RO_BANKS * RO_NUM_TUNE_BITS - 1:0]                ro_tune_sel,
    input  logic [((RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS)) - 1:0]  ro_bank_sel,
    input  logic                                                    meas_start,
    input  logic [31:0]                                             meas_gate_cycles,
    output logic                                                    ro_out,
    output logic [RO_BANKS-1:0]                                     ring_out_bank_bus,
    output logic                                                    meas_busy,
    output logic                                                    meas_done,
    output logic [31:0]                                             meas_edge_count,
    output logic [31:0]                                             meas_freq_hz
);

  localparam int SEL_W = (RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS);

  logic [RO_BANKS-1:0] ring_out_bank;

  function automatic int tail_for_bank(input int bi);
    unique case (bi)
      0, 10: tail_for_bank = 0;
      3:     tail_for_bank = 2;
      1:     tail_for_bank = 4;
      2:     tail_for_bank = 6;
      4:     tail_for_bank = 10;
      7:     tail_for_bank = 14;
      8:     tail_for_bank = 18;
      5:     tail_for_bank = 20;
      9:     tail_for_bank = 26;
      11:    tail_for_bank = 30;
      default: tail_for_bank = -1;
    endcase
  endfunction

  function automatic int chain_stages_for_bank(input int bi);
    unique case (bi)
      6:  chain_stages_for_bank = 601;
      12: chain_stages_for_bank = 401;
      13: chain_stages_for_bank = 501;
      14: chain_stages_for_bank = 601;
      15: chain_stages_for_bank = 801;
      default: chain_stages_for_bank = 0;
    endcase
  endfunction

  function automatic bit bank_active(input int bi);
    unique case (bi)
      0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15:
        bank_active = 1'b1;
      default: bank_active = 1'b0;
    endcase
  endfunction

  generate
    genvar bi;
    for (bi = 0; bi < RO_BANKS; bi++) begin : g_bank
      if (chain_stages_for_bank(bi) > 0) begin : g_chain
        logic ring_chain_raw;
        ring_inverter_chain #(
            .NUM_STAGES(chain_stages_for_bank(bi))
        ) u_ring_slow (
            .en    (ro_en),
            .ro_out(ring_chain_raw)
        );
        ro_ring_prescale #(
            .DIV_BITS(5)
        ) u_chain_out_div (
            .ro_in (ring_chain_raw),
            .rst_n (rst_n),
            .ro_div(ring_out_bank[bi])
        );
      end else if (bank_active(bi) && tail_for_bank(bi) >= 0) begin : g_tune
        ring_inverter_tunable #(
            .NUM_TUNE_BITS     (RO_NUM_TUNE_BITS),
            .NUM_TAIL_INVERTERS(tail_for_bank(bi))
        ) u_ring (
            .en      (ro_en),
            .tune_sel(ro_tune_sel[(bi+1)*RO_NUM_TUNE_BITS-1 : bi*RO_NUM_TUNE_BITS]),
            .ro_out  (ring_out_bank[bi])
        );
      end else begin : g_off
        ring_inverter_tunable #(
            .NUM_TUNE_BITS     (RO_NUM_TUNE_BITS),
            .NUM_TAIL_INVERTERS(2)
        ) u_ring (
            .en      (1'b0),
            .tune_sel({RO_NUM_TUNE_BITS{1'b1}}),
            .ro_out  (ring_out_bank[bi])
        );
      end
    end
  endgenerate

  logic [SEL_W-1:0] bank_eff;
  always_comb begin
    bank_eff = SEL_W'(ro_bank_sel);
    if (RO_BANKS > 1 && SEL_W'(ro_bank_sel) >= SEL_W'(RO_BANKS)) bank_eff = '0;
  end

  generate
    if (RO_BANKS <= 1) begin : g_one
      assign ro_out = ring_out_bank[0];
    end else begin : g_mux
      assign ro_out = ring_out_bank[bank_eff];
    end
  endgenerate

  assign ring_out_bank_bus = ring_out_bank;

  generate
    if (MEAS_ENABLE) begin : g_meas_on
      ro_freq_measure u_measure (
          .clk            (clk),
          .rst_n          (rst_n),
          .ro_async       (ro_out),
          .meas_start     (meas_start),
          .gate_cycles    (meas_gate_cycles),
          .meas_busy      (meas_busy),
          .meas_done      (meas_done),
          .meas_edge_count(meas_edge_count),
          .meas_freq_hz   (meas_freq_hz)
      );
    end else begin : g_meas_off
      logic meas_done_pulse;
      always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) meas_done_pulse <= 1'b0;
        else meas_done_pulse <= meas_start;
      end
      assign meas_busy       = 1'b0;
      assign meas_done       = meas_start & ~meas_done_pulse;
      assign meas_edge_count = '0;
      assign meas_freq_hz    = '0;
    end
  endgenerate

endmodule : ro_top
