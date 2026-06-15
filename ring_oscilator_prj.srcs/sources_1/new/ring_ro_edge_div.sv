// Asynchroniczny licznik binarny taktowany *zboczem narastającym* na wyjściu pierścienia
// (`ro_clk`). MSB zmienia się z przybliżoną częstotliwością ~ f(ro_clk) / 2**WIDTH —
// dla obserwacji na JA przy bardzo powolnym wewnętrznym ROSC.
//
// Uwagi: CLK nie idzie przez BUFG; analiza klasycznego STA jest złudna — dodaj timing false_path
// w XDC dla count_q_reg (timing_arty_s7.xdc). Reset asynchroniczny wzg. ro jest OK przy starcie labu.

`timescale 1ns / 1ps

module ring_ro_edge_div #(
    parameter int WIDTH = 6
) (
    input  logic rst_n,
    input  logic ro_clk,
    output logic div_out_msb
);

  generate
    if (WIDTH < 3 || WIDTH > 24) begin : gen_chk
      initial $fatal(1, "ring_ro_edge_div: WIDTH zakres 3..24 dla sensownego /2^n");
    end
  endgenerate

  (* KEEP = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  logic [WIDTH-1:0] count_q;

  always_ff @(posedge ro_clk or negedge rst_n) begin
    if (!rst_n) count_q <= '0;
    else count_q <= count_q + 1'b1;
  end

  assign div_out_msb = count_q[WIDTH-1];

endmodule : ring_ro_edge_div
