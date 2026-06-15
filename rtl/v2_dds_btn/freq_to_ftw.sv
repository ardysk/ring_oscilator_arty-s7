`timescale 1ns / 1ps

module freq_to_ftw #(
    parameter int F_CLK_HZ = 12_000_000
) (
    input  logic [31:0] freq_hz,
    output logic [31:0] ftw
);

  logic [63:0] num;

  always_comb begin
    if (freq_hz == 32'd0) begin
      ftw = 32'd0;
    end else begin
      num = 64'(freq_hz) * 64'(32'hFFFF_FFFF + 1);
      ftw = 32'(num / 64'(F_CLK_HZ));
    end
  end

endmodule : freq_to_ftw
