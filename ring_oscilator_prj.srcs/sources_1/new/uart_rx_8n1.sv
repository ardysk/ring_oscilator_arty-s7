// Odbiór RS-232 8N1 przy stałej częstotliwości zegara projektu.
`timescale 1ns / 1ps

module uart_rx_8n1 #(
    parameter int CLK_HZ = 12_000_000,
    parameter int BAUD   = 115200
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       rxd_i,
    output logic [7:0] dout,
    output logic       valid  // pojedynczy cykl po odebraniu ramki OK
);

  localparam int unsigned BIT_P = CLK_HZ / BAUD;

  logic [1:0] rxd_ff;
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) rxd_ff <= 2'b11;
    else rxd_ff <= {rxd_ff[0], rxd_i};
  end

  logic rxd;
  assign rxd = rxd_ff[1];  // prosta synchronizacja

  typedef enum logic [1:0] {
    ST_IDLE,
    ST_START,
    ST_BITS,
    ST_STOP
  } st_t;

  st_t           st;
  logic [31:0]   ticks;
  logic [3:0]    nbit;
  logic [7:0]    bufch;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      st      <= ST_IDLE;
      ticks   <= '0;
      nbit    <= '0;
      bufch   <= '0;
      dout    <= '0;
      valid   <= 1'b0;
    end else begin
      valid <= 1'b0;
      unique case (st)
        ST_IDLE: begin
          ticks <= '0;
          if (!rxd) st <= ST_START;
        end

        ST_START: begin
          if (ticks == BIT_P / 2 - 1) begin
            ticks <= '0;
            if (!rxd) begin
              nbit <= '0;
              st   <= ST_BITS;
            end else st <= ST_IDLE;
          end else ticks <= ticks + 32'd1;
        end

        ST_BITS: begin
          if (ticks == BIT_P - 1) begin
            ticks      <= '0;
            bufch[nbit] <= rxd;  // LSB jako pierwszy
            if (nbit == 3'd7) begin
              st <= ST_STOP;
            end else begin
              nbit <= nbit + 4'd1;
            end
          end else ticks <= ticks + 32'd1;
        end

        ST_STOP: begin
          // czekamy cały czas na bit STOP (próbkowanie zbędne przy prostym dekoderze)
          if (ticks == BIT_P - 1) begin
            st    <= ST_IDLE;
            dout  <= bufch;
            valid <= 1'b1;
            ticks <= '0;
          end else ticks <= ticks + 32'd1;
        end

        default: st <= ST_IDLE;
      endcase
    end
  end
endmodule : uart_rx_8n1
