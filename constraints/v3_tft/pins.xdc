## Arty S7-50 — V3 TFT GC9A01 (top: ro_top_v3_wrapper)

set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports clk_12mhz]

set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports ro_scope]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports ro_scope_ring]

## PMOD JC — SPI do GC9A01 (standard Pmod, 3.3V)
## JC1=U15, JC2=V16, JC3=U17, JC4=U18, JC7=U16
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports tft_sck]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports tft_mosi]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports tft_cs_n]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports tft_dc]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports tft_rst_n]

set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {btn[3]}]

set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
