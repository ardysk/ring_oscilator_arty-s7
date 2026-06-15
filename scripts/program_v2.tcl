# Wgranie V2: bitstream + ro_ring_app.elf przez xsdb (JTAG)
set proj_dir [file normalize [file dirname [info script]]/..]
set bit [file normalize [file join $proj_dir bitstreams v2_uart_tft.bit]]
set elf [file normalize [file join $proj_dir sdk_workspace ro_ring_app Debug ro_ring_app.elf]]

if {![file exists $bit]} {
  error "Brak bitstreamu: $bit (uruchom scripts/build_v2_uart_tft.tcl)"
}
if {![file exists $elf]} {
  error "Brak ELF: $elf"
}

connect
targets -set [lindex [targets -filter {level == 0}] 0]
fpga $bit
if {[catch {targets -set -nocase -filter {name =~ "MicroBlaze*#0"} -index 0} _]} {
  targets -set 2
}
rst -processor
dow $elf
con
puts "V2 RUNNING - UART 9600 + TFT na PMOD JD"