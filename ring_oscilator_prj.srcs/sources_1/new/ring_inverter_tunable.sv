// Tunable inverter ring: kombinacyjna pętla ze sprzężeniem zwrotnym (bez wejścia sys_clk) —
// faktyczny „asynchroniczny zegar” ROSC dla labu jest tutaj realizowany przez propagacje w LUT.
// NAND enable zamyka pętle (en=0 → mid=1); każdy segment mux: bypass lub dwa invertory LUT.
// MUX+LUTH always w torze → narzut MUX podobny dla każdej kombinacji; różnica to 0 vs 2 inv.
// NUM_TAIL_INVERTERS must be even (0,2,…) so total inversions around loop stay odd.
//
// Symulacja BEH prawach zachowuje ten sam opis co synteza (czyste assign, bez #(…)).
// Zero-opóźnieniowa pętla kombinacyjna może na XSim pozostawić ro_out w stanie X/Z — wtedy
// włącz w projekcie symulacji TransportPathDelay/IntDelay (jak w .xpr) albo akceptuj „synteza = prawda”.

`timescale 1ns / 1ps

module ring_inverter_tunable #(
    parameter int NUM_TUNE_BITS     = 4,
    parameter int NUM_TAIL_INVERTERS = 2
) (
    input  logic                  en,
    input  logic [NUM_TUNE_BITS-1:0] tune_sel,
    output logic                  ro_out
);
  generate
    if (NUM_TUNE_BITS < 1) begin : g_bad1
      initial $error("ring_inverter_tunable: NUM_TUNE_BITS must be >= 1");
    end
    if (NUM_TUNE_BITS > 16) begin : g_tune_max
      initial $error("ring_inverter_tunable: NUM_TUNE_BITS > 16 zwykle zbędnie kosztuje LUT — zmniejsz parametr");
    end
    if (NUM_TAIL_INVERTERS < 0 || (NUM_TAIL_INVERTERS % 2) != 0) begin : g_bad2
      initial $error("ring_inverter_tunable: NUM_TAIL_INVERTERS must be even && >= 0");
    end
  endgenerate

  (* KEEP = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  logic fb;

  (* KEEP = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  logic mid;

  assign mid = ~(fb & en);

  (* KEEP = "TRUE" *)
  (* DONT_TOUCH = "TRUE" *)
  logic [NUM_TUNE_BITS:0] tnode;

  assign tnode[0] = mid;

  genvar k, j;
  generate
    for (k = 0; k < NUM_TUNE_BITS; k++) begin : g_tune
      (* KEEP = "TRUE" *)
      (* DONT_TOUCH = "TRUE" *)
      logic d1, d2;
      assign d1 = ~tnode[k];
      assign d2 = ~d1;
      assign tnode[k+1] = tune_sel[k] ? d2 : tnode[k];
    end
  endgenerate

  logic tail_end;
  generate
    if (NUM_TAIL_INVERTERS == 0) begin : g_zero_tail
      assign tail_end = tnode[NUM_TUNE_BITS];
    end else begin : g_tail_inv
      (* KEEP = "TRUE" *)
      (* DONT_TOUCH = "TRUE" *)
      logic [NUM_TAIL_INVERTERS:0] tailv;
      assign tailv[0] = tnode[NUM_TUNE_BITS];
      for (j = 0; j < NUM_TAIL_INVERTERS; j++) begin : g_tv
        assign tailv[j+1] = ~tailv[j];
      end
      assign tail_end = tailv[NUM_TAIL_INVERTERS];
    end
  endgenerate

  assign fb     = tail_end;
  assign ro_out = fb;

endmodule : ring_inverter_tunable
