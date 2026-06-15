`timescale 1ns / 1ps

module ro_target_map #(
    parameter int BANK_SEL_W      = 4,
    parameter int RO_BANKS        = 16,
    parameter int DIV_CNT_W       = 16,
    parameter int TARGET_KHZ_MAX  = 65535
) (
    input  logic [15:0]           target_khz,
    input  logic                  bank_manual,
    input  logic [BANK_SEL_W-1:0] bank_override,
    output logic [BANK_SEL_W-1:0] bank_auto,
    output logic [DIV_CNT_W-1:0]  half_edges,
    output logic                  div_bypass,
    output logic [15:0]           f_pred_khz
);

  localparam logic [DIV_CNT_W-1:0] EDGE_MAX_HOLD = {DIV_CNT_W{1'b1}};
  localparam int unsigned MUX_MATCH_PCT = 32'd25;

  function automatic int unsigned f_ro_hz_for_bank(input int unsigned b);
    unique case (b)
      10: return 32'd120_000_000;
      0:  return 32'd100_000_000;
      3:  return 32'd55_000_000;
      4:  return 32'd20_000_000;
      5:  return 32'd15_000_000;
      6:  return 32'd1_000_000;
      default: return 32'd20_000_000;
    endcase
  endfunction

  function automatic int unsigned abs_diff_hz(input int unsigned a, input int unsigned b);
    if (a >= b) return a - b;
    else return b - a;
  endfunction

  always_comb begin
    int unsigned t_khz;
    int unsigned t_hz;
    int unsigned b;
    int unsigned b_pick;
    int unsigned b_div;
    int unsigned f_b;
    int unsigned fbase;
    int unsigned err;
    int unsigned err_best;
    int unsigned hh;
    int unsigned fout_hz;

    t_khz = unsigned'(target_khz);
    if (t_khz < 32'd1) t_khz = 32'd1;
    if (t_khz > unsigned'(TARGET_KHZ_MAX)) t_khz = unsigned'(TARGET_KHZ_MAX);
    t_hz = t_khz * 32'd1000;

    b_pick   = 32'd0;
    err_best = 32'hFFFF_FFFF;

    if (t_hz < 32'd500_000) begin
      b_pick = unsigned'(RO_BANKS) - 32'd1;
    end else if (t_hz < 32'd2_000_000) begin
      b_pick = unsigned'(RO_BANKS) - 32'd2;
    end else begin
      for (b = 32'd0; b < unsigned'(RO_BANKS); b++) begin
        f_b = f_ro_hz_for_bank(b);
        err = abs_diff_hz(f_b, t_hz);
        if (err < err_best) begin
          err_best = err;
          b_pick   = b;
        end
      end
    end
    bank_auto = BANK_SEL_W'(b_pick);

    b_div = bank_manual ? unsigned'(bank_override) : b_pick;
    if (b_div >= unsigned'(RO_BANKS)) b_div = 32'd0;
    fbase = f_ro_hz_for_bank(b_div);

    hh = (fbase + t_hz) / (unsigned'(2) * t_hz);
    if (hh < 32'd1) hh = 32'd1;
    if (hh > unsigned'(EDGE_MAX_HOLD)) hh = unsigned'(EDGE_MAX_HOLD);
    div_bypass = 1'b0;
    half_edges = DIV_CNT_W'(hh);
    fout_hz    = fbase / (unsigned'(2) * hh);

    f_pred_khz = 16'((fout_hz + 32'd500) / 32'd1000);
  end

endmodule
