`timescale 1ns / 1ps

module ro_top_zed #(
    parameter int RO_BANKS              = 4,
    parameter int RO_NUM_TUNE_BITS       = 10,
    parameter int RO_NUM_TAIL_INVERTERS = 2,
    parameter [31:0] MEAS_GATE_CYCLES_DEFAULT = 32'd1_250_000
) (
    input  logic       clk_100mhz,
    input  logic       btnc,
    input  logic       btnu,
    input  logic       btnr,
    input  logic       btnl,
    input  logic       btnd,
    input  logic [7:0] sw,
    output logic [7:0] led,
    output logic       ro_scope
);

  logic        rst_n;
  logic        ro_en;
  logic        meas_start;
  (* DONT_TOUCH = "yes" *)
  logic [31:0] meas_gate_cycles;
  logic        ro_out;
  logic        meas_busy;
  logic        meas_done;
  logic [31:0] meas_edge_count;
  logic [31:0] meas_freq_hz;

  logic [7:0] led_latched;

  localparam int SEL_W   = (RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS);
  localparam int TUNE_BW = RO_BANKS * RO_NUM_TUNE_BITS;

  logic [TUNE_BW-1:0] ro_tune_bus;
  logic [SEL_W-1:0]   ro_bank_sel;

  wire [9:0] tune_full_dip =
      {btnu, btnr, btnl, btnd, sw[7], sw[6], sw[5], sw[4], sw[3], sw[2]};
  wire [9:0] tune_b4 =
      {btnu, btnr, btnl, btnd, sw[5], sw[4], sw[3], sw[2], 1'b0, 1'b0};
  wire [9:0] tune_b2 = {btnu, btnr, btnl, btnd, sw[6], sw[5], sw[4], sw[3], sw[2], 1'b0};

  wire [9:0] tune_one =
      (RO_BANKS <= 1) ? tune_full_dip :
      (RO_BANKS == 2) ? tune_b2 :
                         tune_b4;

  generate
    if (RO_NUM_TUNE_BITS != 10) begin : gen_fixed_width
      initial $fatal(1, "ro_top_zed: RO_NUM_TUNE_BITS musi być 10 dla tego wrappera.");
    end
    if ((RO_BANKS != 1) && (RO_BANKS != 2) && (RO_BANKS != 4)) begin : gen_banks_ok
      initial $fatal(1, "ro_top_zed: ustaw RO_BANKS na 1, 2 lub 4.");
    end
  endgenerate

  assign rst_n      = btnc;
  assign ro_en      = sw[0];
  assign meas_start = sw[1];
  assign ro_tune_bus = {RO_BANKS{tune_one}};
  assign ro_bank_sel =
      (RO_BANKS <= 1) ? SEL_W'(1'b0) :
      (RO_BANKS == 2) ? SEL_W'(sw[7]) :
                        SEL_W'(sw[7:6]);

  assign meas_gate_cycles = MEAS_GATE_CYCLES_DEFAULT;

  (* keep_hierarchy = "yes" *)
  ro_top #(
      .RO_BANKS             (RO_BANKS),
      .RO_NUM_TUNE_BITS     (RO_NUM_TUNE_BITS),
      .RO_NUM_TAIL_INVERTERS(RO_NUM_TAIL_INVERTERS)
  ) u_core (
      .clk              (clk_100mhz),
      .rst_n            (rst_n),
      .ro_en            (ro_en),
      .ro_tune_sel      (ro_tune_bus),
      .ro_bank_sel      (ro_bank_sel),
      .meas_start       (meas_start),
      .meas_gate_cycles (meas_gate_cycles),
      .ro_out           (ro_out),
      .meas_busy        (meas_busy),
      .meas_done        (meas_done),
      .meas_edge_count  (meas_edge_count),
      .meas_freq_hz     (meas_freq_hz)
  );

  assign ro_scope = ro_out;

  always_ff @(posedge clk_100mhz or negedge rst_n) begin
    if (!rst_n) led_latched <= '0;
    else if (meas_done) led_latched <= meas_edge_count[7:0];
  end

  assign led = meas_busy ? 8'hAA : led_latched;

endmodule : ro_top_zed
