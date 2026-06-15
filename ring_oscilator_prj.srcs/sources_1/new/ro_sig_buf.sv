// Pojedynczy BUFG na sygnale po dzielniku/mux (wyjście OUT).
`timescale 1ns / 1ps

module ro_sig_buf (
    input  logic sig_in,
    output logic sig_out
);

  BUFG u_bufg (
      .I(sig_in),
      .O(sig_out)
  );

endmodule
