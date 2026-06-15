# Wgranie V1: bitstream + firmware przez xsdb (JTAG)
set proj_dir [file normalize [file dirname [info script]]/..]
set bit [file normalize [file join $proj_dir bitstreams v1_uart.bit]]
set elf_fw [file normalize [file join $proj_dir firmware ro_ring_app.elf]]
set elf_sdk [file normalize [file join $proj_dir sdk_workspace ro_ring_app Debug ro_ring_app.elf]]

if {![file exists $bit]} {
  error "Brak bitstreamu: $bit (uruchom scripts/build_v1.tcl)"
}

set elf $elf_fw
if {![file exists $elf] && [file exists $elf_sdk]} {
  set elf $elf_sdk
}
if {![file exists $elf]} {
  error "Brak firmware ELF: $elf_fw (skopiuj ro_ring_app.elf do firmware/ lub zbuduj SDK)"
}

puts "BIT: $bit"
puts "ELF: $elf"

connect
targets -set [lindex [targets -filter {level == 0}] 0]
fpga $bit
puts "Bitstream OK"

if {[catch {targets -set -nocase -filter {name =~ "MicroBlaze*#0"} -index 0} _]} {
  targets -set 2
}
rst -processor
dow $elf
con
puts "V1 RUNNING — terminal COM13 9600 8N1, wpisz HELP"
