# Re-assign PBLOCK cells after synth and re-run implementation only.
set proj_dir [file normalize [file dirname [info script]]/..]
cd $proj_dir

if {[file exists ring_oscilator_prj.xpr]} {
  open_project ring_oscilator_prj.xpr
} else {
  error "No project: ring_oscilator_prj.xpr"
}

open_run synth_1
proc ensure_ro_pblocks {} {
  set fp_xdc [file normalize constraints/v1_uart/floorplan_ro_banks.xdc]
  if {![file exists $fp_xdc]} { return }
  foreach pb {pblock_ro_bank10 pblock_ro_bank3 pblock_ro_bank4 pblock_ro_bank5} {
    set old [get_pblocks -quiet $pb]
    if {$old ne ""} { catch {delete_pblocks $old} }
  }
  read_xdc $fp_xdc
}
ensure_ro_pblocks
foreach {pb bank} {
  pblock_ro_bank10 10
  pblock_ro_bank3  3
  pblock_ro_bank4  4
  pblock_ro_bank5  5
} {
  set pat "*g_bank\[$bank\]*"
  set cells [get_cells -hierarchical -quiet -filter "NAME =~ $pat"]
  if {[llength $cells] > 0} {
    catch {add_cells_to_pblock [get_pblocks $pb] $cells} err
    if {$err ne ""} { puts "WARN PBLOCK $pb: $err" }
    puts "PBLOCK $pb: [llength $cells] cells"
  } else {
    puts "WARN PBLOCK $pb: no cells matched $pat"
  }
}

reset_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
  error "impl_1 failed"
}

file mkdir bitstreams
set bit_src "ring_oscilator_prj.runs/impl_1/mb_ro_system_wrapper.bit"
file copy -force $bit_src bitstreams/v1_uart.bit

open_run impl_1
source [file normalize scripts/gen_lut_mapping.tcl]

catch {close_project}
puts "DONE: bitstreams/v1_uart.bit"
