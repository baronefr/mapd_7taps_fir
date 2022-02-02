#!/usr/bin/python3

##   MAPD modA - Barone Francesco Pio
##  
## This script feeds the FIR coefficients to the FPGA through USB interface.
##
##  call this script as      ./write_coefficients.py  <coeff_file>
##     example:    ./send_data_fpga.py waveform_test/waveform_sample.txt waveform_test/fpga_sampling.txt
##

import serial
import numpy as np
import sys
import argparse


parser = argparse.ArgumentParser(description='Send coefficients to FPGA.')
parser.add_argument('--usb', type=str, nargs=1, help='set the USB device used for communication with FPGA')
parser.add_argument('-i', '--input', type=str, nargs=1, help='file with values to send through USB')
parser.add_argument('-c', '--coeff', type=str, nargs='+', help='manually provide the coefficients (int)')
args = parser.parse_args()


# parsing the USB interface
if args.usb == None: interface = '/dev/ttyUSB1'
else: interface = str(args.usb[0])
print(f' >> using interface {interface}')

# parsing the coefficients file
if args.input == None:  coeffs_file = 'coeffs.txt'
else:  coeffs_file = args.input[0]

# parsing the output file
if args.coeff == None: data = None
else: data = np.array(args.coeff, dtype=int)

# internal settings
print_fpga_uart = False        # if True, will print on terminal the output of FPGA
input_threshold = 120          # maximum value for threshold warning




###########################
#          I/O            #
###########################

if args.coeff == None:
    try:
        print(' > reading coefficients from file', coeffs_file)
        data = np.genfromtxt(coeffs_file, dtype=int)
        print(f' > {len(data)} values acquired')
    except:
        print(' [ERROR]  no coeffs file found!')
        exit(0)

print(' >> coefficients: ', data)




###########################
#        serial           #
###########################

print(' << serial >>')
ser = serial.Serial(interface, baudrate = 115200, bytesize=8, stopbits=1)

for count, value in enumerate(data):

    if abs(value) > input_threshold:  print('limit error!')
    
    bit_sequence = ( int(value) ).to_bytes(1, byteorder='big', signed=True)
    
    ser.write( bit_sequence )
    print('.')

print('>> end of buffer')

