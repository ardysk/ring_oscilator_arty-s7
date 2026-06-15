## PBLOCK floorplan — banks 3, 4, 5 (spread LUT delay on Spartan-7 xc7s50)

create_pblock pblock_ro_bank3
resize_pblock [get_pblocks pblock_ro_bank3] -add {SLICE_X0Y0:SLICE_X10Y20}
set_property IS_SOFT FALSE [get_pblocks pblock_ro_bank3]

create_pblock pblock_ro_bank4
resize_pblock [get_pblocks pblock_ro_bank4] -add {SLICE_X30Y0:SLICE_X40Y25}
set_property IS_SOFT FALSE [get_pblocks pblock_ro_bank4]

create_pblock pblock_ro_bank5
resize_pblock [get_pblocks pblock_ro_bank5] -add {SLICE_X50Y50:SLICE_X60Y75}
set_property IS_SOFT FALSE [get_pblocks pblock_ro_bank5]

## Assign after synthesis (hierarchical names from ro_top u_core)
proc assign_ro_bank_pblocks {} {
  set patterns {
    {pblock_ro_bank3  {*u_core/g_bank[3]*}}
    {pblock_ro_bank4  {*u_core/g_bank[4]*}}
    {pblock_ro_bank5  {*u_core/g_bank[5]*}}
  }
  foreach {pb pat} $patterns {
    set cells [get_cells -hierarchical -quiet -filter "NAME =~ $pat"]
    if {[llength $cells] > 0} {
      add_cells_to_pblock [get_pblocks $pb] $cells
      puts "PBLOCK $pb: [llength $cells] cells"
    } else {
      puts "WARN: no cells for $pb ($pat)"
    }
  }
}

## Hook from build script after synth if needed:
# assign_ro_bank_pblocks
