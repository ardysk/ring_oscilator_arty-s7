start_gui
puts "Vivado GUI started (needed for show_schematic/write_schematic)."

set root [file normalize [file join [file dirname [info script]] ".."]]
set out_dir [file normalize [file join $root "docs" "vivado_schematics" "svg"]]

file mkdir $out_dir

proc _read_v1_rtl {root} {
  set rtl_dir [file join $root "rtl" "common"]
  set srcs [glob -nocomplain -directory $rtl_dir *.sv]
  foreach f $srcs {
    read_verilog -sv $f
  }

  # Some wrapper files are Verilog, keep them if present.
  set wraps [list \
    [file join $rtl_dir "ro_top_arty_axi_bd_wrap.v"] \
  ]
  foreach f $wraps {
    if {[file exists $f]} { read_verilog $f }
  }
}

proc _export_one {top part out_svg} {
  if {[current_design -quiet] ne ""} {
    catch { close_design }
  }

  synth_design -top $top -part $part -flatten_hierarchy none -no_lc
  # GUI-only: create schematic window and export it
  show_schematic -name "Schematic" [get_nets]
  write_schematic -format svg -name "Schematic" -force $out_svg
  catch { close_design }
}

set part "xc7s50csga324-1"

create_project -in_memory -part $part
set_property target_language Verilog [current_project]
set_property default_lib work [current_project]

_read_v1_rtl $root
update_compile_order -fileset sources_1

# V1 blocks (RTL) to export. Note: Vivado BD canvas export isn't available in batch in 2018.3.
set blocks [list \
  ro_top_arty_axi \
  csr_ro_axi_lite \
  ro_multi_div_mux \
  ro_target_map \
  ro_ring_bank_buf \
  ring_prog_toggle_div \
  ro_sig_buf \
  ro_bank_prescale_mux \
  ro_ring_prescale \
  ro_freq_measure \
  ro_freq_hz_calc \
  ro_top \
  ring_inverter_tunable \
  ring_inverter_chain \
  arty_scope_freq_mux \
]

foreach b $blocks {
  puts "== Export schematic: $b =="
  set out_svg [file join $out_dir "${b}.svg"]
  _export_one $b $part $out_svg
}

puts "Done. SVG schematics in: $out_dir"
exit

