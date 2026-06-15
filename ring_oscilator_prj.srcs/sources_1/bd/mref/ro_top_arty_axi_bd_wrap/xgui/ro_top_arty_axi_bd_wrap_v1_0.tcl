# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "MEAS_GATE_CYCLES_DEFAULT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RO_BANKS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RO_NUM_TAIL_INVERTERS" -parent ${Page_0}
  ipgui::add_param $IPINST -name "RO_NUM_TUNE_BITS" -parent ${Page_0}


}

proc update_PARAM_VALUE.MEAS_GATE_CYCLES_DEFAULT { PARAM_VALUE.MEAS_GATE_CYCLES_DEFAULT } {
	# Procedure called to update MEAS_GATE_CYCLES_DEFAULT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MEAS_GATE_CYCLES_DEFAULT { PARAM_VALUE.MEAS_GATE_CYCLES_DEFAULT } {
	# Procedure called to validate MEAS_GATE_CYCLES_DEFAULT
	return true
}

proc update_PARAM_VALUE.RO_BANKS { PARAM_VALUE.RO_BANKS } {
	# Procedure called to update RO_BANKS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RO_BANKS { PARAM_VALUE.RO_BANKS } {
	# Procedure called to validate RO_BANKS
	return true
}

proc update_PARAM_VALUE.RO_NUM_TAIL_INVERTERS { PARAM_VALUE.RO_NUM_TAIL_INVERTERS } {
	# Procedure called to update RO_NUM_TAIL_INVERTERS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RO_NUM_TAIL_INVERTERS { PARAM_VALUE.RO_NUM_TAIL_INVERTERS } {
	# Procedure called to validate RO_NUM_TAIL_INVERTERS
	return true
}

proc update_PARAM_VALUE.RO_NUM_TUNE_BITS { PARAM_VALUE.RO_NUM_TUNE_BITS } {
	# Procedure called to update RO_NUM_TUNE_BITS when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.RO_NUM_TUNE_BITS { PARAM_VALUE.RO_NUM_TUNE_BITS } {
	# Procedure called to validate RO_NUM_TUNE_BITS
	return true
}


proc update_MODELPARAM_VALUE.RO_NUM_TUNE_BITS { MODELPARAM_VALUE.RO_NUM_TUNE_BITS PARAM_VALUE.RO_NUM_TUNE_BITS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RO_NUM_TUNE_BITS}] ${MODELPARAM_VALUE.RO_NUM_TUNE_BITS}
}

proc update_MODELPARAM_VALUE.RO_NUM_TAIL_INVERTERS { MODELPARAM_VALUE.RO_NUM_TAIL_INVERTERS PARAM_VALUE.RO_NUM_TAIL_INVERTERS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RO_NUM_TAIL_INVERTERS}] ${MODELPARAM_VALUE.RO_NUM_TAIL_INVERTERS}
}

proc update_MODELPARAM_VALUE.RO_BANKS { MODELPARAM_VALUE.RO_BANKS PARAM_VALUE.RO_BANKS } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.RO_BANKS}] ${MODELPARAM_VALUE.RO_BANKS}
}

proc update_MODELPARAM_VALUE.MEAS_GATE_CYCLES_DEFAULT { MODELPARAM_VALUE.MEAS_GATE_CYCLES_DEFAULT PARAM_VALUE.MEAS_GATE_CYCLES_DEFAULT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MEAS_GATE_CYCLES_DEFAULT}] ${MODELPARAM_VALUE.MEAS_GATE_CYCLES_DEFAULT}
}

