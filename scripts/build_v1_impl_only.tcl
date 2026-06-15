set proj_dir [file normalize [file dirname [info script]]/..]
cd $proj_dir
open_project ring_oscilator_prj.xpr

open_run synth_1
foreach {pb pat} {
  pblock_ro_bank3 {*u_core/g_bank\[3\]*}
  pblock_ro_bank4 {*u_core/g_bank\[4\]*}
  pblock_ro_bank5 {*u_core/g_bank\[5\]*}
} {
  set cells [get_cells -hierarchical -quiet -filter "NAME =~ $pat"]
  if {[llength $cells] > 0} {
    catch {add_cells_to_pblock [get_pblocks $pb] $cells}
    puts "PBLOCK $pb: [llength $cells] cells"
  }
}

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} { error "impl failed" }

file mkdir bitstreams
file copy -force ring_oscilator_prj.runs/impl_1/mb_ro_system_wrapper.bit bitstreams/v1_uart.bit
open_run impl_1
report_timing_summary -file bitstreams/v1_uart_timing.rpt
catch {source scripts/gen_lut_mapping.tcl}
close_project
puts "DONE bitstreams/v1_uart.bit"
