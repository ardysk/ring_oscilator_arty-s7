`timescale 1ns / 1ps

module ro_bank_prescale_mux #(
    parameter int RO_BANKS   = 16,
    parameter int BANK_SEL_W = (RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS)
) (
    input  logic                  ro_in,
    input  logic                  rst_n,
    input  logic [BANK_SEL_W-1:0] bank_sel,
    output logic                  ro_div,
    output logic [31:0]           scale_out
);

  function automatic int div_bits_for_bank(input logic [3:0] b);
    unique case (b)
      4'd0, 4'd10: div_bits_for_bank = 9;
      4'd1, 4'd2, 4'd3: div_bits_for_bank = 7;
      4'd4, 4'd7, 4'd8: div_bits_for_bank = 5;
      4'd5, 4'd6, 4'd9, 4'd11, 4'd12, 4'd13, 4'd14, 4'd15:
        div_bits_for_bank = 3;
      default: div_bits_for_bank = 6;
    endcase
  endfunction

  logic ro_ps9, ro_ps7, ro_ps5, ro_ps3;

  ro_ring_prescale #(.DIV_BITS(9)) u_ps9 (.ro_in(ro_in), .rst_n(rst_n), .ro_div(ro_ps9));
  ro_ring_prescale #(.DIV_BITS(7)) u_ps7 (.ro_in(ro_in), .rst_n(rst_n), .ro_div(ro_ps7));
  ro_ring_prescale #(.DIV_BITS(5)) u_ps5 (.ro_in(ro_in), .rst_n(rst_n), .ro_div(ro_ps5));
  ro_ring_prescale #(.DIV_BITS(3)) u_ps3 (.ro_in(ro_in), .rst_n(rst_n), .ro_div(ro_ps3));

  always_comb begin
    logic [9:0] db;
    db = 10'(div_bits_for_bank(4'(bank_sel)));
    scale_out = 32'd1 << (db + 1);
    unique case (4'(bank_sel))
      4'd0, 4'd10: ro_div = ro_ps9;
      4'd1, 4'd2, 4'd3: ro_div = ro_ps7;
      4'd4, 4'd7, 4'd8: ro_div = ro_ps5;
      default: ro_div = ro_ps3;
    endcase
  end

endmodule
