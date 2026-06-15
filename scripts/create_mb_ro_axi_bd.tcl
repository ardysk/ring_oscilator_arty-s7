#
# Ścieżka B: MicroBlaze @12 MHz + AXI4-Lite do ro_top_arty_axi (przez ro_top_arty_axi_bd_wrap.v).
#
# Wywołanie (PowerShell):
#   cd ...\ring_oscilator_prj
#   & "C:\Xilinx\Vivado\2018.3\bin\vivado.bat" -mode batch -source scripts/create_mb_ro_axi_bd.tcl
#
# Po sukcesie w Vivado: włącz constrs pins_arty_mb_axi.xdc, wyłącz pins_arty_s7.xdc (DIP),
# ustaw Top module na mb_ro_system_wrapper, zsyntetyzuj. W Vitis: BSP + main.c wg docs/MicroBlaze_AXI_Arty.md.
#

proc remove_bd_design_by_file {name} {
  set bf [get_files ${name}.bd -quiet]
  if {$bf eq ""} { return }

  puts "Removing existing BD ${name}.bd ..."
  catch {close_bd_design -quiet}
  open_bd_design $bf

  set d [current_bd_design -quiet]
  if {$d ne ""} {
    delete_bd_objs $d
  }
  catch {close_bd_design -quiet}
  remove_files -fileset sources_1 $bf
}

open_project ring_oscilator_prj.xpr

update_compile_order -fileset sources_1

# Odśwież definicję module_ref po zmianach w wrapperze (port ro_scope_ring, RO_BANKS=8)
catch {update_module_reference -force ro_top_arty_axi_bd_wrap}

catch {close_bd_design -quiet}

# Wrapper z poprzedniego przebiegu (ten sam basename co Vivado wygeneruje)
set old_wrap [get_files mb_ro_system_wrapper.v -quiet]
if {$old_wrap ne ""} {
  puts "Removing old wrapper verilog $old_wrap"
  remove_files -fileset sources_1 $old_wrap
}

remove_bd_design_by_file mb_ro_system

puts "Creating mb_ro_system ..."

create_bd_design mb_ro_system

create_bd_port -dir I -type clk clk_12mhz
catch {set_property CONFIG.FREQ_HZ 12000000 [get_bd_ports clk_12mhz]}

create_bd_cell -type ip -vlnv xilinx.com:ip:microblaze:11.0 microblaze_0

apply_bd_automation -rule xilinx.com:bd_rule:microblaze \
  -config [list \
    local_mem "128KB" \
    ecc "None" \
    cache "None" \
    debug_module "Debug Only" \
    axi_periph "Enabled" \
    axi_intc "0" \
    clk "/clk_12mhz"] \
  [get_bd_cells microblaze_0]

create_bd_cell -type module -reference ro_top_arty_axi_bd_wrap ro_axi_0

# Zegar procesora = 12 MHz (ta sama sieć co CSR i pierścień)

connect_bd_net [get_bd_ports clk_12mhz] [get_bd_pins ro_axi_0/clk_12mhz]
connect_bd_net [get_bd_ports clk_12mhz] [get_bd_pins ro_axi_0/s_axi_aclk]

# Reset AXI dla pierścienia: z proc_sys_reset (automation po MB)
set pr [lindex [get_bd_cells -filter {VLNV =~ *proc_sys_reset*}] 0]
if {$pr eq ""} {
  error "Nie znaleziono komórki proc_sys_reset po block automation MB."
}

connect_bd_net [get_bd_pins $pr/peripheral_aresetn] [get_bd_pins ro_axi_0/s_axi_aresetn]

create_bd_port -dir I -from 3 -to 0 btn
create_bd_port -dir I -from 3 -to 0 sw
create_bd_port -dir O -from 3 -to 0 led
create_bd_port -dir O ro_scope
create_bd_port -dir O ro_scope_ring

set_property -dict [list CONFIG.RO_BANKS {16} CONFIG.RO_NUM_TUNE_BITS {12}] [get_bd_cells ro_axi_0]

connect_bd_net [get_bd_ports btn]  [get_bd_pins ro_axi_0/btn]
connect_bd_net [get_bd_ports sw]   [get_bd_pins ro_axi_0/sw]
connect_bd_net [get_bd_pins ro_axi_0/led]      [get_bd_ports led]
connect_bd_net [get_bd_pins ro_axi_0/ro_scope] [get_bd_ports ro_scope]
connect_bd_net [get_bd_pins ro_axi_0/ro_scope_ring] [get_bd_ports ro_scope_ring]

puts "Inferowane intf ro_axi_0:"
foreach i [lsort [get_bd_intf_pins -of_objects [get_bd_cells ro_axi_0]]] {
  puts "  INTF $i"
}

apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
  -config [list Master "/microblaze_0 (Periph)" Clk "Auto" ] \
  [get_bd_intf_pins ro_axi_0/S_AXI]

# UART USB (9600) — stdout/printf na port COM w PC (Tera Term / Python)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0
set_property -dict [list CONFIG.C_BAUDRATE {9600}] [get_bd_cells axi_uartlite_0]
connect_bd_net [get_bd_ports clk_12mhz] [get_bd_pins axi_uartlite_0/s_axi_aclk]
connect_bd_net [get_bd_pins $pr/peripheral_aresetn] [get_bd_pins axi_uartlite_0/s_axi_aresetn]

apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
  -config [list Master "/microblaze_0 (Periph)" Clk "Auto" ] \
  [get_bd_intf_pins axi_uartlite_0/S_AXI]

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:uart_rtl:1.0 uart_usb
connect_bd_intf_net [get_bd_intf_ports uart_usb] [get_bd_intf_pins axi_uartlite_0/UART]

# JTAG UART w MDM — dodatkowo widoczny w konsoli SDK przy debug
set mdm [get_bd_cells mdm_1 -quiet]
if {$mdm ne ""} {
  set_property -dict [list CONFIG.C_USE_UART {1}] $mdm
  set mdm_aclk [get_bd_pins -quiet $mdm/S_AXI_ACLK]
  if {$mdm_aclk ne ""} {
    connect_bd_net [get_bd_ports clk_12mhz] $mdm_aclk
  }
}

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_rsthigh
set_property -dict [list CONFIG.CONST_WIDTH {1} CONFIG.CONST_VAL {1}] [get_bd_cells xlconstant_rsthigh]
set rer [get_bd_pins -quiet /rst_clk_12mhz_12M/ext_reset_in]
if {$rer ne ""} {
  puts "Tie HIGH ext_reset_in na proc_sys przy clk 12 MHz: $rer"
  connect_bd_net [get_bd_pins xlconstant_rsthigh/dout] $rer
} else {
  puts "UWAGA: nie znaleziono /rst_clk_12mhz_12M/ext_reset_in — ustaw xlconstant_recznie w BD."
}

validate_bd_design
save_bd_design

puts "--- Mapowanie adresów (segments; jeśli puste, zajrzyj do Address Editor) ---"
if {[catch {
  foreach seg [get_bd_addr_segs [get_bd_addr_spaces microblaze_0/Data]] {
    puts "  SEG name=[get_property NAME $seg] OFFSET=[get_property OFFSET $seg] RANGE=0x[format %x [get_property RANGE $seg]]"
  }
} adr_err]} {
  puts "  (print warn) $adr_err"
}

puts "Generowanie HDL wrapper ..."
set wf [make_wrapper -files [get_files mb_ro_system.bd] -top]
add_files -norecurse $wf
update_compile_order -fileset sources_1

puts "DONE."
puts "--> Project Settings: Top module = mb_ro_system_wrapper."
puts "--> Constrs: wlacz pins_arty_mb_axi.xdc, wylacz (UserDisabled) pins_arty_s7.xdc (porty sw[*])."

