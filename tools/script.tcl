##   MAPD modA - Barone Francesco Pio
##  This script uses vivado in TCL mode to program the FPGA.
##

open_hw
connect_hw_server
open_hw_target

set_property PROGRAM.FILE {../bit/fir_switch.bit} [current_hw_device]  
program_hw_devices [current_hw_device]

close_hw_target
exit
