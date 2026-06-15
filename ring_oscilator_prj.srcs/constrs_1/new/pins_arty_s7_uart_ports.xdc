## Porty UART (FT2232) jak w Digilent Arty-S7-50-Master.xdc — tylko dla topu z `uart_*` np. ro_top_arty_uart.
## W projekcie: UserDisabled=ON dopóki top = ro_top_arty ; po przełączeniu top + włącz ten plik razem z pins_arty_s7.xdc.

set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports uart_txd_in]
set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports uart_rxd_out]
