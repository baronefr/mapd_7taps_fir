#!/usr/bin/python3

##   MAPD modA - Barone Francesco Pio
##  
## This script feeds a waveform (given as a txt file) to the FPGA through USB interface. It is required that
##  the values in txt file are stored as signed integer values, non-exceeding 8 bits to avoid overflow issues.
##
##  call this script as      ./send_data_fpga.py  -i <data_file>  -o <output_file>
##     example:    ./send_data_fpga.py -i waveform_test/waveform_sample.txt -o waveform_test/fpga_sampling.txt
##
##       -- data_file is the file of the sample waveform
##       -- output_file is the file used to store the output of FPGA
##      If no arguments are provided, the I/O takes value from the Default variables in this script.
##
##    Flag --usb can be used to specify the USB interface. By default we use /dev/ttyUSB1

import serial
import numpy as np
import sys
import argparse


parser = argparse.ArgumentParser(description='Send data to fpga & retrieve output values.')
parser.add_argument('--usb', type=str, nargs=1, help='set the USB device used for communication with FPGA')
parser.add_argument('-i', '--input', type=str, nargs=1, help='file with values to send through USB')
parser.add_argument('-o', '--output', type=str, nargs=1, help='file with output of FPGA')
args = parser.parse_args()


# parsing the USB interface
if args.usb == None: interface = '/dev/ttyUSB1'
else: interface = str(args.usb[0])
print(f' >> using interface {interface}')

# parsing the input file
if args.input == None:  data_file = 'waveform_sample.txt'
else:  data_file = args.input[0]

# parsing the output file
if args.output == None: output_file = 'fpga_sampling.txt'   # default value
else: output_file = args.output[0]

print(f' === {data_file}  -> FPGA ->  {output_file} ===')

# internal settings
print_fpga_uart = False        # if True, will print on terminal the output of FPGA
input_threshold = 101          # maximum value for threshold warning



###########################
#          I/O            #
###########################

try:
    print(' > read values from file', data_file)
    data = np.genfromtxt(data_file, dtype=int)
    print(f' > {len(data)} values acquired')
    #print(data)
except:
    print(' [ERROR]  no input file found!')
    exit(0)

textfile = open(output_file, "w")


###########################
#        serial           #
###########################

print(' << serial >>')
ser = serial.Serial(interface, baudrate = 115200, bytesize=8, stopbits=1)

for count, value in enumerate(data):

    if abs(value) > input_threshold: print('limit threshold warning!')

    bit_sequence = ( int(value) ).to_bytes(1, byteorder='big', signed=True)
    
    ser.write( bit_sequence )
    d = ser.read()
    
    conv_value = int.from_bytes(d, byteorder='big', signed=True)

    if print_fpga_uart:  print(f'fpga[{count}]:', conv_value )
    elif not count%(int(len(data)/10)): print('.')
    textfile.write( str(conv_value) + "\n")
    
textfile.close()

print('>> end of buffer')
