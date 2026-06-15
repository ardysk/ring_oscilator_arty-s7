// Arty S7-50: jak `ro_top_arty`, lecz strojenie 10-bit z PC przez UART + bank kilku RO (równolegle + MUX).
// sw[3:2] → ro_bank_sel (przy RO_BANKS=4). sw[0]=ro_en sw[1]=meas_start btn[3]=rst.
//
// W Vivado ustaw syntetyzowany top na `ro_top_arty_uart` i w constrs odkomentuj / włącz `pins_arty_s7_uart_ports.xdc`.
`timescale 1ns / 1ps

module ro_top_arty_uart #(
    parameter int RO_BANKS              = 4,
    parameter int RO_NUM_TUNE_BITS       = 10,
    parameter int RO_NUM_TAIL_INVERTERS = 2,
    parameter [31:0] MEAS_GATE_CYCLES_DEFAULT =
        // ~12.5 ms @ 12 MHz
        32'd150_000
) (
    input  logic       clk_12mhz,
    input  logic [3:0] btn,
    input  logic [3:0] sw,
    input  logic       uart_txd_in,
    output logic       uart_rxd_out,
    output logic [3:0] led,
    output logic       ro_scope
);

  logic rst_n;
  logic ro_en;
  logic meas_start;
  (* DONT_TOUCH = "yes" *)
  logic [31:0] meas_gate_cycles;
  logic ro_out;
  logic meas_busy;
  logic meas_done;
  logic [31:0] meas_edge_count;
  logic [31:0] meas_freq_hz;

  logic [3:0] led_lat;

  localparam int SEL_W   = (RO_BANKS <= 1) ? 1 : $clog2(RO_BANKS);
  localparam int TUNE_BW = RO_BANKS * RO_NUM_TUNE_BITS;

  logic [TUNE_BW-1:0] ro_tune_bus;
  logic [RO_NUM_TUNE_BITS-1:0] ro_tune_uart;
  logic [SEL_W-1:0]           ro_bank_sel;

  generate
    if (RO_NUM_TUNE_BITS != 10) begin : gen_width
      initial $fatal(1, "ro_top_arty_uart: RO_NUM_TUNE_BITS musi być 10.");
    end
    if ((RO_BANKS != 2) && (RO_BANKS != 4)) begin : gb
      initial $fatal(1, "ro_top_arty_uart: RO_BANKS=2 lub 4 (mapowanie sw[3:2]).");
    end
  endgenerate

  assign rst_n      = ~btn[3];
  assign ro_en      = sw[0];
  assign meas_start = sw[1];
  assign meas_gate_cycles = MEAS_GATE_CYCLES_DEFAULT;
  assign uart_rxd_out = 1'b1;

  logic [7:0] uart_d;
  logic       uart_v;

  uart_rx_8n1 #(
      .CLK_HZ(12_000_000),
      .BAUD  (115200)
  ) u_uart_rx (
      .clk(clk_12mhz),
      .rst_n(rst_n),
      .rxd_i(uart_txd_in),
      .dout(uart_d),
      .valid(uart_v)
  );

  tune_cmd_uart u_tune_cmd (
      .clk(clk_12mhz),
      .rst_n(rst_n),
      .uart_data(uart_d),
      .uart_valid(uart_v),
      .tune_out(ro_tune_uart)
  );

  assign ro_tune_bus = {RO_BANKS{ro_tune_uart}};
  assign ro_bank_sel = SEL_W'(sw[3 -: SEL_W]);

  (* keep_hierarchy = "yes" *)
  ro_top #(
      .RO_BANKS             (RO_BANKS),
      .RO_NUM_TUNE_BITS     (RO_NUM_TUNE_BITS),
      .RO_NUM_TAIL_INVERTERS(RO_NUM_TAIL_INVERTERS)
  ) u_core (
      .clk              (clk_12mhz),
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

  always_ff @(posedge clk_12mhz or negedge rst_n) begin
    if (!rst_n) led_lat <= '0;
    else if (meas_done) led_lat <= meas_edge_count[3:0];
  end

  assign led = meas_busy ? 4'hA : led_lat;

endmodule : ro_top_arty_uart
