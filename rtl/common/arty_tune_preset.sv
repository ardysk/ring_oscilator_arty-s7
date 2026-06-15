`timescale 1ns / 1ps

module arty_tune_preset #(
    parameter int WIDTH = 10
) (
    input  logic [               2:0] preset_idx,
    output logic [WIDTH-1:0] tune_sel
);

  always_comb begin
    unique case (preset_idx)
      3'd0: tune_sel = 10'h3FF;
      3'd1: tune_sel = 10'h2DB;
      3'd2: tune_sel = 10'h1F7;
      3'd3: tune_sel = 10'h155;
      3'd4: tune_sel = 10'h0ED;
      3'd5: tune_sel = 10'h07B;
      3'd6: tune_sel = 10'h02D;
      3'd7: tune_sel = 10'h000;
      default: tune_sel = 10'h3FF;
    endcase
  end

endmodule
