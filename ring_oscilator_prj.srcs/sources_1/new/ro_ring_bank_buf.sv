// BUFG na każdym wyjściu pierścienia — tor pomiarowy/dzielnika nie dotyka LUT pętli.
`timescale 1ns / 1ps

module ro_ring_bank_buf #(
    parameter int RO_BANKS = 8
) (
    input  logic [RO_BANKS-1:0] ring_in,
    output logic [RO_BANKS-1:0] ring_buf
);

  generate
    genvar gi;
    for (gi = 0; gi < RO_BANKS; gi++) begin : g_buf
      BUFG u_bufg (
          .I(ring_in[gi]),
          .O(ring_buf[gi])
      );
    end
  endgenerate

endmodule
