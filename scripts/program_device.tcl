# Programuje Spartan-7 z pliku ro_top_arty.bit (JTAG).
#
# UWAGA (Vivado 2018.3): polecenie open_hw_manager dziala tylko w pelnym GUI Vivado — NIE dziala
# przy vivado.bat -mode batch ani -mode tcl. Uruchom:
#   1. Otworz Vivado GUI i projekt ring_oscilator_prj.xpr
#   2. Tcl Console na dole lub Window -> Tcl Console:
#          source scripts/program_device.tcl
#    lub recznie: Flow -> Open Hardware Manager -> Auto Connect/open target ->
#               prawym na FPGA -> Program Device -> wybierz ro_top_arty.bit

set script_dir [file dirname [file normalize [info script]]]
set proj_dir [file normalize [file join $script_dir ..]]
set bit_file [file join $proj_dir ro_top_arty.bit]

if {![file isfile $bit_file]} {
  puts "ERROR: Brak bitstreamu — zbuduj projekt:"
  puts "       vivado -mode batch -source scripts/build_all_to_bit.tcl"
  return
}

if {[info commands open_hw_manager] eq ""} {
  puts "ERROR: open_hw_manager niedostepne — potrzebne pelne Vivado GUI + otwarty projekt (.xpr)."
  puts "Sciezka bitstreamu recznego: $bit_file"
  return
}

puts "PROGRAM.FILE -> $bit_file"

if {[catch {
  open_hw_manager
  connect_hw_server
  open_hw_target

  set devs [get_hw_devices]
  if {[llength $devs] == 0} {
    error "Brak HW device — sprawdz Digilent/USB-JTAG, zasil Arty i Open target ponownie."
  }
  current_hw_device [lindex $devs 0]
  puts "DEVICE: [get_property NAME [current_hw_device]]"

  set_property PROGRAM.FILE $bit_file [current_hw_device]
  set_property PROBES.FILE {} [current_hw_device]
  set_property FULL_PROBES.FILE {} [current_hw_device]
  program_hw_devices [current_hw_device]

} msg]} {
  puts "ERROR programowanie: $msg"
  puts "PROGRAM.FILE mozesz wybrac w GUI: Hardware Manager -> Program device -> $bit_file"
  return
}

puts "OK: program_device zakonczone pomyslnie."
