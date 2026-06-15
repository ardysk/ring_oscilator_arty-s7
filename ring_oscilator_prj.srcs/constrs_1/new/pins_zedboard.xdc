## ZedBoard — wg Digilent Zedboard-Master.xdc (poprawione SW3–SW7, banki napięć)
## Przełączniki i BTNC: Bank 34/35 → domyślnie LVCMOS18 (Vadj / jumper — sprawdź płytkę).
## LED: Bank 33 → LVCMOS33. Zegar + Pmod JA: Bank 13 → LVCMOS33.

## Clock (Bank 13)
set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]

## JA Pmod pin 1 (Bank 13) — tap RO
set_property -dict {PACKAGE_PIN Y11 IOSTANDARD LVCMOS33} [get_ports ro_scope]

## LEDs (Bank 33)
set_property -dict {PACKAGE_PIN T22 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN T21 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN U22 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN U21 IOSTANDARD LVCMOS33} [get_ports {led[3]}]
set_property -dict {PACKAGE_PIN V22 IOSTANDARD LVCMOS33} [get_ports {led[4]}]
set_property -dict {PACKAGE_PIN W22 IOSTANDARD LVCMOS33} [get_ports {led[5]}]
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports {led[6]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {led[7]}]

## Centre push-button (Bank 34)
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS18} [get_ports btnc]

## Direction buttons — dodatkowe bity strojenia ro_tune_sel[9:6] na ZedBoard
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS18} [get_ports btnu]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS18} [get_ports btnr]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS18} [get_ports btnl]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS18} [get_ports btnd]

## DIP switches (Bank 35) — nazewnictwo jak w master XDC Avnet/Digilent
set_property -dict {PACKAGE_PIN F22 IOSTANDARD LVCMOS18} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN G22 IOSTANDARD LVCMOS18} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN H22 IOSTANDARD LVCMOS18} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN F21 IOSTANDARD LVCMOS18} [get_ports {sw[3]}]
set_property -dict {PACKAGE_PIN H19 IOSTANDARD LVCMOS18} [get_ports {sw[4]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS18} [get_ports {sw[5]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS18} [get_ports {sw[6]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS18} [get_ports {sw[7]}]
