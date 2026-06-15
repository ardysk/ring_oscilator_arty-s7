## timing — top ro_top_arty (CLK12MHZ ok. 83,333 ns)
create_clock -name clk_sys -period 83.333 -waveform {0 41.667} [get_ports clk_12mhz]

## Domyślna analiza: wbudowany MMCM w u_scope generuje domyślny zegar potomny (Vivado inferuje).
## Przy ostrych TIMING na ja_scope można dodać create_generated_clock na u_scope/bufg_out/O.

## Licznik taktowany zboczem RO (`ring_prog_toggle_div`) — zbocza fabric, nie BUFG-sys.

set_false_path -to [get_cells -hierarchical -filter {NAME =~ *u_hz_scope_div/*}]
