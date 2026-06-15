set proj_dir [file normalize [file dirname [info script]]/..]
cd $proj_dir
open_project ring_oscilator_prj.xpr
reset_run synth_1
reset_run impl_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} { error "synth failed" }
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
