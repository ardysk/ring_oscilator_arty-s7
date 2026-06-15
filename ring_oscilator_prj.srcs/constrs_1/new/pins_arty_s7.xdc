## Arty S7-50 (XC7S50-CSGA324) — piny jak w Digilent Arty-S7-50-Master.xdc (Rew. E+).
## Porty topu muszą zgadać się z ro_top_arty.sv

## Clock 12 MHz
set_property -dict {PACKAGE_PIN F14 IOSTANDARD LVCMOS33} [get_ports clk_12mhz]

## Pmod JA — pin L17 = przedefiniowany sygnał (dzielnik / bypass), pin L18 = zsynchronizowany tap pierścienia

set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports ro_scope]

set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports ro_scope_ring]

## LEDs (mono)
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## Przyciski (wciśnięty = wysokie)
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {btn[0]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {btn[1]}]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports {btn[2]}]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {btn[3]}]

## DIP (4 szt.)
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN M5 IOSTANDARD SSTL135} [get_ports {sw[3]}]

## Bitstream / BANK 34 — z master XDC (SW3 jako zwykłe IO w banku DDR)
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property INTERNAL_VREF 0.675 [get_iobanks 34]
