`timescale 1ns / 1ps

module dds_phase_accum (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        en,
    input  logic [31:0] ftw,
    output logic [31:0] phase
);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) phase <= '0;
    else if (en) phase <= phase + ftw;
  end

endmodule : dds_phase_accum
