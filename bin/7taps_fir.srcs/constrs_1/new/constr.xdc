set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { CLK100MHZ }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { CLK100MHZ }];

set_property -dict { PACKAGE_PIN D10   IOSTANDARD LVCMOS33 } [get_ports { fpga_tx }]; #IO_L19N_T3_VREF_16 Sch=uart_rxd_out
set_property -dict { PACKAGE_PIN A9    IOSTANDARD LVCMOS33 } [get_ports { fpga_rx }]; #IO_L14N_T2_SRCC_16 Sch=uart_txd_in

set_property -dict { PACKAGE_PIN A8   IOSTANDARD LVCMOS33 } [get_ports { program_switch }];
set_property -dict { PACKAGE_PIN H5   IOSTANDARD LVCMOS33 } [get_ports { led_operating }];
set_property -dict { PACKAGE_PIN G6   IOSTANDARD LVCMOS33 } [get_ports { led_programming }];
set_property -dict { PACKAGE_PIN E1   IOSTANDARD LVCMOS33 } [get_ports { led_programming_ok }];