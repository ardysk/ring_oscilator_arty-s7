## timing.xdc — top `ro_top_zed` (zegar 100 MHz na Bank 13)

create_clock -name clk -period 10.000 [get_ports clk_100mhz]

## CDC: zsynchronizowane próbki RO
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *u_measure/ro_s0_reg}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *u_measure/ro_s1_reg}]
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *u_measure/ro_s2_reg}]

## Wejścia/wyjścia: dodaj opóźnienia po zdefiniowaniu interfejsu zewnętrznego.
