# PBLOCK regions for RO banks — sourced by build_v1.tcl / auto_tune.py
source [file normalize [file join [file dirname [info script]] .. constraints v1_uart floorplan_ro_banks.xdc]]

if {[llength [get_pblocks -quiet pblock_ro_bank3]] > 0} {
  proc assign_ro_bank_pblocks {} {
    foreach {pb pat} {
      {pblock_ro_bank0  {*u_core/g_bank[0]*}}
      {pblock_ro_bank1  {*u_core/g_bank[1]*}}
      {pblock_ro_bank2  {*u_core/g_bank[2]*}}
      {pblock_ro_bank3  {*u_core/g_bank[3]*}}
      {pblock_ro_bank4  {*u_core/g_bank[4]*}}
      {pblock_ro_bank5  {*u_core/g_bank[5]*}}
      {pblock_ro_bank6  {*u_core/g_bank[6]*}}
      {pblock_ro_bank7  {*u_core/g_bank[7]*}}
      {pblock_ro_bank8  {*u_core/g_bank[8]*}}
      {pblock_ro_bank9  {*u_core/g_bank[9]*}}
      {pblock_ro_bank10 {*u_core/g_bank[10]*}}
      {pblock_ro_bank11 {*u_core/g_bank[11]*}}
      {pblock_ro_bank12 {*u_core/g_bank[12]*}}
      {pblock_ro_bank13 {*u_core/g_bank[13]*}}
      {pblock_ro_bank14 {*u_core/g_bank[14]*}}
      {pblock_ro_bank15 {*u_core/g_bank[15]*}}
    } {
      set cells [get_cells -hierarchical -quiet -filter "NAME =~ $pat"]
      if {[llength $cells] > 0} {
        catch {add_cells_to_pblock [get_pblocks $pb] $cells}
      }
    }
  }
}
