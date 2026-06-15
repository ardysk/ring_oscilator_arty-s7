# V1: mb_ro_system_wrapper — naprawa module_ref + pełny rebuild
set proj_dir [file normalize [file dirname [info script]]/..]
cd $proj_dir
open_project ring_oscilator_prj.xpr

# Ensure new synthesizer RTL is in project
set src_new [file normalize ring_oscilator_prj.srcs/sources_1/new]
foreach sv {ro_ring_prescale.sv ro_bank_prescale_mux.sv ro_freq_measure.sv ro_freq_hz_calc.sv} {
  set p [file join $src_new $sv]
  if {[file exists $p] && [get_files -quiet [list $p]] eq ""} {
    add_files -norecurse $p
    set_property used_in_synthesis true [get_files $p]
    set_property used_in_implementation true [get_files $p]
  }
}
set fp_xdc [file normalize constraints/v1_uart/floorplan_ro_banks.xdc]
if {[file exists $fp_xdc] && [get_files -quiet [list $fp_xdc]] eq ""} {
  add_files -fileset constrs_1 -norecurse $fp_xdc
}

proc enable_v1_sources {} {
  foreach f [get_files -quiet -of_objects [get_filesets sources_1] *] {
    set tail [file tail $f]
    if {[string match *mb_ro_system* $tail] ||
        [string match *ro_top_arty_axi* $tail] ||
        [string match *csr_ro_axi* $tail] ||
        [string match mb_ro_system_wrapper.v $tail]} {
      set_property IS_ENABLED true $f
    }
  }
  foreach f [get_files -quiet *mb_ro_system.bd] {
    set_property IS_ENABLED true $f
  }
}

proc disable_v2_v3_sources {} {
  foreach tail {
    ro_top_v2.sv ro_top_v3.sv ro_top_v3_wrapper.v
    btn_freq_selector.sv dds_core.sv dds_phase_accum.sv freq_to_ftw.sv
    btn_debouncer.sv ro_output_buffer.sv ro_bank_mux.sv
    spi_master.sv gc9a01_driver.sv
  } {
    set ff [get_files -quiet *${tail}]
    if {$ff ne ""} { set_property IS_ENABLED false $ff }
  }
}

enable_v1_sources
disable_v2_v3_sources

# Vivado 2018.3: brak flagi -force
if {[catch {update_module_reference ro_top_arty_axi_bd_wrap} err]} {
  puts "WARN update_module_reference: $err"
}

set bd [get_files mb_ro_system.bd -quiet]
if {$bd eq ""} {
  error "Brak mb_ro_system.bd"
}

# Skip BD repair when create_mb_ro_axi_bd.tcl already wired ro_axi @ 0x44A00000

# Regeneruj outputy IP (stub/dcp) po uszkodzeniu przez wcześniejsze buildy
catch {reset_target all $bd}
generate_target all $bd
export_ip_user_files -of_objects $bd -no_script -sync -force -quiet

# OOC synteza sekwencyjnie (Windows: unikaj locków na katalogach run)
foreach r [lsort [get_runs -filter {NAME =~ mb_ro_system*_synth_1}]] {
  puts "OOC synth: $r"
  catch {reset_run $r}
  launch_runs $r -jobs 4
  wait_on_run $r
  set prog [get_property PROGRESS $r]
  set stat [get_property STATUS $r]
  puts "OOC done: $r progress=$prog status=$stat"
  if {$prog != "100%"} {
    error "OOC synthesis failed: $r (status=$stat)"
  }
}

set_property top mb_ro_system_wrapper [current_fileset]
set_property top_file [get_files mb_ro_system_wrapper.v] [current_fileset]

foreach {pat en} {
  pins_arty_mb_axi 1
  pins_v2_dds_btn 0
  pins_v3_tft 0
  pins_arty_s7.xdc 0
  pins_zedboard 0
  timing_arty_s7 1
  floorplan_ro_banks 1
  floorplan 0
  ring_oscloop 0
} {
  foreach f [get_files -quiet -of_objects [get_filesets constrs_1] *${pat}*] {
    set_property IS_ENABLED $en $f
  }
}

foreach tail {
  ro_ring_prescale.sv ro_bank_prescale_mux.sv
  ro_freq_measure.sv ro_freq_hz_calc.sv
} {
  set ff [get_files -quiet *${tail}]
  if {$ff eq ""} {
    puts "WARN: add $tail to project sources_1/new"
  } else {
    set_property IS_ENABLED true $ff
  }
}

update_compile_order -fileset sources_1
reset_run synth_1
reset_run impl_1

launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
  error "V1 top synthesis failed"
}

open_run synth_1
foreach pb {pblock_ro_bank10 pblock_ro_bank3 pblock_ro_bank4 pblock_ro_bank5} {
  set old [get_pblocks -quiet $pb]
  if {$old ne ""} { catch {delete_pblocks $old} }
}
if {[file exists $fp_xdc]} {
  read_xdc $fp_xdc
}
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

launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
  error "V1 implementation failed"
}

file mkdir bitstreams
set bit_src "ring_oscilator_prj.runs/impl_1/mb_ro_system_wrapper.bit"
if {![file exists $bit_src]} {
  error "Bitstream missing: $bit_src"
}
file copy -force $bit_src bitstreams/v1_uart.bit

open_run impl_1
report_timing_summary -file bitstreams/v1_uart_timing.rpt

set gen_lut [file normalize scripts/gen_lut_mapping.tcl]
if {[file exists $gen_lut]} {
  source $gen_lut
}

catch {close_project}
puts "V1 DONE: bitstreams/v1_uart.bit"
