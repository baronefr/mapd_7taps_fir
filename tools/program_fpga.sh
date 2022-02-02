#!/bin/bash

##   MAPD modA - Barone Francesco Pio
##  
##  This script calls Vivado to program an FPGA through the bitstream file, without
##   launching the Vivado UI.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)

cd $SCRIPT_DIR  # note: use paths wrt tools folder!
vivado -mode tcl -nolog -nojournal -source script.tcl
rm .Xil -R
exit
