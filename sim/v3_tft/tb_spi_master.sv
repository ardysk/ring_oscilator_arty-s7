//--------------------------------------------------------------------------------
// Company:       CSD Lab6
// Engineer:      Ring Oscillator Project
//
// Create Date:   2026-06-06
// Design Name:   tb_spi_master
// Module Name:   tb_spi_master
// Project Name:  ring_oscilator_prj
// Target Devices: Simulation
// Tool Versions: Vivado 2018.3
// Description:   Testbench SPI master — transmisja bajtu 0xA5.
//
// Revision:
// Revision 0.01 - File Created
//--------------------------------------------------------------------------------
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
