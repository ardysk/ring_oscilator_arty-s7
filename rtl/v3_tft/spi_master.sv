// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// SPI mode-0 master with programmable clock division for display and peripheral IO.
// Shifts one byte per transaction and handshakes with busy/done status.
// Used by gc9a01_driver in the V3 TFT experimental design.

`timescale 1ns / 1ps

module spi_master #(
    parameter int CLK_DIV = 16
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [7:0]  tx_data,
    output logic        busy,
    output logic        done,
    output logic        sck,
    output logic        mosi
);

  typedef enum logic [1:0] {ST_IDLE, ST_RUN, ST_DONE} st_t;
  st_t state;

  logic [7:0] shreg;
  logic [3:0] bit_idx;
  logic [7:0] div;
  logic       sck_r;

  assign sck  = sck_r;
  assign mosi = shreg[7];

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state   <= ST_IDLE;
      shreg   <= '0;
      bit_idx <= '0;
      div     <= '0;
      sck_r   <= 1'b0;
      busy    <= 1'b0;
      done    <= 1'b0;
    end else begin
      done <= 1'b0;
      unique case (state)
        ST_IDLE: begin
          busy <= 1'b0;
          sck_r <= 1'b0;
          if (start) begin
            shreg   <= tx_data;
            bit_idx <= 4'd0;
            div     <= '0;
            busy    <= 1'b1;
            state   <= ST_RUN;
          end
        end

        ST_RUN: begin
          if (div == CLK_DIV[7:0] - 1) begin
            div <= '0;
            sck_r <= ~sck_r;
            if (sck_r) begin
              shreg <= {shreg[6:0], 1'b0};
              if (bit_idx == 4'd7) begin
                sck_r <= 1'b0;
                state <= ST_DONE;
              end else begin
                bit_idx <= bit_idx + 4'd1;
              end
            end
          end else begin
            div <= div + 8'd1;
          end
        end

        ST_DONE: begin
          busy <= 1'b0;
          done <= 1'b1;
          state <= ST_IDLE;
        end

        default: state <= ST_IDLE;
      endcase
    end
  end

endmodule
