# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  set C_S00_AXI_DATA_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_DATA_WIDTH" -parent ${Page_0} -widget comboBox]
  set_property tooltip {Width of S_AXI data bus} ${C_S00_AXI_DATA_WIDTH}
  set C_S00_AXI_ADDR_WIDTH [ipgui::add_param $IPINST -name "C_S00_AXI_ADDR_WIDTH" -parent ${Page_0} -show_range false]
  set_property tooltip {Width of S_AXI address bus} ${C_S00_AXI_ADDR_WIDTH}
  ipgui::add_param $IPINST -name "C_S00_AXI_BASEADDR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "C_S00_AXI_HIGHADDR" -parent ${Page_0}

  set FIR_DSP_NR [ipgui::add_param $IPINST -name "FIR_DSP_NR"]
  set_property tooltip {Check in your fpga documentation how many blocks are available} ${FIR_DSP_NR}
  set TM [ipgui::add_param $IPINST -name "TM" -show_range false]
  set_property tooltip {Higher time multiplexing rank gives higher kernel ranks and decreases band width.} ${TM}
  set FIR_COEF_MAG [ipgui::add_param $IPINST -name "FIR_COEF_MAG"]
  set_property tooltip {Coefficients should be converted by multiplying by 2^FIR_COEF_MAG} ${FIR_COEF_MAG}
  set SRC_COEF_MAG [ipgui::add_param $IPINST -name "SRC_COEF_MAG"]
  set_property tooltip {Coefficients should be converted by multiplying by 2^SRC_COEF_MAG} ${SRC_COEF_MAG}
  ipgui::add_param $IPINST -name "INPUT_DATA_WIDTH"
  ipgui::add_param $IPINST -name "OUTPUT_DATA_WIDTH"
  set SRC_DSP_NR [ipgui::add_param $IPINST -name "SRC_DSP_NR"]
  set_property tooltip {total DSP used for SRC = SRC_DSP_NR x 2 + 1} ${SRC_DSP_NR}

}

proc update_PARAM_VALUE.FIR_COEF_MAG { PARAM_VALUE.FIR_COEF_MAG } {
	# Procedure called to update FIR_COEF_MAG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIR_COEF_MAG { PARAM_VALUE.FIR_COEF_MAG } {
	# Procedure called to validate FIR_COEF_MAG
	return true
}

proc update_PARAM_VALUE.FIR_DSP_NR { PARAM_VALUE.FIR_DSP_NR } {
	# Procedure called to update FIR_DSP_NR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FIR_DSP_NR { PARAM_VALUE.FIR_DSP_NR } {
	# Procedure called to validate FIR_DSP_NR
	return true
}

proc update_PARAM_VALUE.INPUT_DATA_WIDTH { PARAM_VALUE.INPUT_DATA_WIDTH } {
	# Procedure called to update INPUT_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.INPUT_DATA_WIDTH { PARAM_VALUE.INPUT_DATA_WIDTH } {
	# Procedure called to validate INPUT_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.OUTPUT_DATA_WIDTH { PARAM_VALUE.OUTPUT_DATA_WIDTH } {
	# Procedure called to update OUTPUT_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUTPUT_DATA_WIDTH { PARAM_VALUE.OUTPUT_DATA_WIDTH } {
	# Procedure called to validate OUTPUT_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.SRC_COEF_MAG { PARAM_VALUE.SRC_COEF_MAG } {
	# Procedure called to update SRC_COEF_MAG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SRC_COEF_MAG { PARAM_VALUE.SRC_COEF_MAG } {
	# Procedure called to validate SRC_COEF_MAG
	return true
}

proc update_PARAM_VALUE.SRC_DSP_NR { PARAM_VALUE.SRC_DSP_NR } {
	# Procedure called to update SRC_DSP_NR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SRC_DSP_NR { PARAM_VALUE.SRC_DSP_NR } {
	# Procedure called to validate SRC_DSP_NR
	return true
}

proc update_PARAM_VALUE.TM { PARAM_VALUE.TM } {
	# Procedure called to update TM when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.TM { PARAM_VALUE.TM } {
	# Procedure called to validate TM
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.FIR_DSP_NR { MODELPARAM_VALUE.FIR_DSP_NR PARAM_VALUE.FIR_DSP_NR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIR_DSP_NR}] ${MODELPARAM_VALUE.FIR_DSP_NR}
}

proc update_MODELPARAM_VALUE.FIR_COEF_MAG { MODELPARAM_VALUE.FIR_COEF_MAG PARAM_VALUE.FIR_COEF_MAG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FIR_COEF_MAG}] ${MODELPARAM_VALUE.FIR_COEF_MAG}
}

proc update_MODELPARAM_VALUE.TM { MODELPARAM_VALUE.TM PARAM_VALUE.TM } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.TM}] ${MODELPARAM_VALUE.TM}
}

proc update_MODELPARAM_VALUE.INPUT_DATA_WIDTH { MODELPARAM_VALUE.INPUT_DATA_WIDTH PARAM_VALUE.INPUT_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.INPUT_DATA_WIDTH}] ${MODELPARAM_VALUE.INPUT_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.OUTPUT_DATA_WIDTH { MODELPARAM_VALUE.OUTPUT_DATA_WIDTH PARAM_VALUE.OUTPUT_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUTPUT_DATA_WIDTH}] ${MODELPARAM_VALUE.OUTPUT_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.SRC_COEF_MAG { MODELPARAM_VALUE.SRC_COEF_MAG PARAM_VALUE.SRC_COEF_MAG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SRC_COEF_MAG}] ${MODELPARAM_VALUE.SRC_COEF_MAG}
}

proc update_MODELPARAM_VALUE.SRC_DSP_NR { MODELPARAM_VALUE.SRC_DSP_NR PARAM_VALUE.SRC_DSP_NR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SRC_DSP_NR}] ${MODELPARAM_VALUE.SRC_DSP_NR}
}

