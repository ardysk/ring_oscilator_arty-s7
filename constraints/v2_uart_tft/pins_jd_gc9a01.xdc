## Arty S7-50 — GC9A01 na PMOD JD (od gory: VCC GND SCL SDA DC CS RST)
## JD3=SCL  JD4=SDA(MOSI)  JD7=DC  JD8=CS  JD9=RST

set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports tft_sck]
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports tft_mosi]
set_property -dict {PACKAGE_PIN T13 IOSTANDARD LVCMOS33} [get_ports tft_dc]
set_property -dict {PACKAGE_PIN R11 IOSTANDARD LVCMOS33} [get_ports tft_cs_n]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports tft_rst_n]
