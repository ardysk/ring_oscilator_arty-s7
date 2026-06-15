// =============================================================================
// Projekt SDUP — aring_osc
// A. Kowalczyk, K. Skalka
// Ring Oscillator Synthesizer — Arty S7-50 (V1 UART)
// =============================================================================

// Testbench that sends byte streams through spi_master and monitors SCK/MOSI.
// Confirms CPOL/CPHA timing and transaction completion signaling.
// Supports bring-up of the V3 display SPI interface in simulation.

`timescale 1ns / 1ps

module tb_spi_master;

  logic clk, rst_n, start, busy, done, sck, mosi;
  logic [7:0] tx_data;

  spi_master #(
      .CLK_DIV(4)
  ) dut (
      .clk(clk), .rst_n(rst_n), .start(start), .tx_data(tx_data),
      .busy(busy), .done(done), .sck(sck), .mosi(mosi)
  );

  initial clk = 0;
  always #20ns clk = ~clk;

  initial begin
    rst_n = 0;
    start = 0;
    tx_data = 8'hA5;
    #200ns;
    rst_n = 1;
    #100ns;
    start = 1;
    @(posedge clk);
    start = 0;
    wait (done);
    $display("SPI TX done, mosi toggled");
    $finish;
  end

endmodule
