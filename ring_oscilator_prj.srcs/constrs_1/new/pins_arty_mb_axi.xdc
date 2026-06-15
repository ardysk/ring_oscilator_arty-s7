## Arty S7-50 — piny dla topu wygenerowanego z Block Design MicroBlaze (mb_ro_system_wrapper).
## Brak portów DIP (sw) — przy buildzie z procesorem wyłącz pins_arty_s7.xdc (DIP) żeby uniknąć get_ports na sw[*].

set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports clk_12mhz]

set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports ro_scope]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports ro_scope_ring]

# USB-UART (FTDI) — zgodnie z Digilent Arty-S7-50-Master.xdc:
#   V12 = FPGA RX (uart_txd_in),  R12 = FPGA TX (uart_rxd_out)
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {uart_usb_rxd}]
set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports {uart_usb_txd}]

set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {btn[3]}]

set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN M5  IOSTANDARD LVCMOS33} [get_ports {sw[3]}]

set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property INTERNAL_VREF 0.675 [get_iobanks 34]
