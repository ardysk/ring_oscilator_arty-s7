`timescale 1ns / 1ps

module btn_freq_selector #(
    parameter int TARGET_MHZ_MIN = 1,
    parameter int TARGET_MHZ_MAX = 511,
    parameter int STEP_MHZ       = 1
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        btn_up_pulse,
    input  logic        btn_dn_pulse,
    input  logic        btn_meas_pulse,
    output logic [8:0]  target_mhz,
    output logic        meas_pulse
);

  logic [8:0] target_q;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      target_q <= 9'd10;
    end else begin
      if (btn_up_pulse && !btn_dn_pulse) begin
        if (int'(target_q) + STEP_MHZ <= TARGET_MHZ_MAX)
          target_q <= 9'(int'(target_q) + STEP_MHZ);
      end else if (btn_dn_pulse && !btn_up_pulse) begin
        if (int'(target_q) - STEP_MHZ >= TARGET_MHZ_MIN)
          target_q <= 9'(int'(target_q) - STEP_MHZ);
      end
    end
  end

  assign target_mhz = target_q;
  assign meas_pulse = btn_meas_pulse;

endmodule : btn_freq_selector
