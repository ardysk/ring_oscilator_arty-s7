// Pomiar z mnożnikiem częstotliwości (np. tor /64 przed licznikiem → skala ×64).
`timescale 1ns / 1ps

module ro_freq_measure_scaled #(
    parameter int RO_SYNC_STAGES = 3,
    parameter int F_REF_HZ       = 12_000_000,
    parameter int FREQ_SCALE     = 1
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        ro_async,
    input  logic        meas_start,
    input  logic [31:0] gate_cycles,
    output logic        meas_busy,
    output logic        meas_done,
    output logic [31:0] meas_edge_count,
    output logic [31:0] meas_freq_hz
);

  logic [31:0] freq_raw;

  ro_freq_measure #(
      .RO_SYNC_STAGES(RO_SYNC_STAGES),
      .F_REF_HZ      (F_REF_HZ)
  ) u_core (
      .clk            (clk),
      .rst_n          (rst_n),
      .ro_async       (ro_async),
      .meas_start     (meas_start),
      .gate_cycles    (gate_cycles),
      .meas_busy      (meas_busy),
      .meas_done      (meas_done),
      .meas_edge_count(meas_edge_count),
      .meas_freq_hz   (freq_raw)
  );

  assign meas_freq_hz = (freq_raw > (32'hFFFF_FFFF / FREQ_SCALE)) ?
      32'hFFFF_FFFF : (freq_raw * 32'(FREQ_SCALE));

endmodule
