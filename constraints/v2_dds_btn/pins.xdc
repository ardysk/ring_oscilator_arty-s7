## Arty S7-50 — V2 DDS + przyciski (top: ro_top_v2)

set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports clk_12mhz]

set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports ro_scope]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports ro_scope_ring]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports dds_out]

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
