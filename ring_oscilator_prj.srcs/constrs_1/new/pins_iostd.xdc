## Minimalne ograniczenia we/wy — pełny bitstream wymaga PACKAGE_PIN dla każdego portu.
## Zegar systemowy ZedBoard PL (100 MHz): Y9 (sprawdź w User Guide dla swojej rewizji).

set_property -dict {PACKAGE_PIN Y9 IOSTANDARD LVCMOS33} [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports]
