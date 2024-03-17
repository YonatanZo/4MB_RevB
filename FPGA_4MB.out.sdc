## Generated SDC file "FPGA_4MB.out.sdc"

## Copyright (C) 2022  Intel Corporation. All rights reserved.
## Your use of Intel Corporation's design tools, logic functions 
## and other software and tools, and any partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Intel Program License 
## Subscription Agreement, the Intel Quartus Prime License Agreement,
## the Intel FPGA IP License Agreement, or other applicable license
## agreement, including, without limitation, that your use is for
## the sole purpose of programming logic devices manufactured by
## Intel and sold by Intel or its authorized distributors.  Please
## refer to the applicable agreement for further details, at
## https://fpgasoftware.intel.com/eula.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 21.1.1 Build 850 06/23/2022 SJ Lite Edition"

## DATE    "Mon Jan 16 09:16:42 2023"

##
## DEVICE  "10M40DCF256I7G"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk_100m} -period 10.000 -waveform { 5.000 10.000 } [get_ports { clk_100m }]
create_clock -name {spiclk} -period 50.000 -waveform { 0.000 25.000 } [get_ports { mclk_0 }]


#**************************************************************
# Create Generated Clock
#**************************************************************



#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************



#**************************************************************
# Set Input Delay
#**************************************************************

set_input_delay -add_delay -rise -clock [get_clocks {spiclk}]  0.200 [get_ports {cs_00}]
set_input_delay -add_delay -fall -max -clock [get_clocks {spiclk}]  0.500 [get_ports {cs_00}]
set_input_delay -add_delay -fall -min -clock [get_clocks {spiclk}]  0.200 [get_ports {cs_00}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {spiclk}]  0.500 [get_ports {cs_00}]
set_input_delay -add_delay -rise -clock [get_clocks {spiclk}]  0.200 [get_ports {mosi_0}]
set_input_delay -add_delay -fall -max -clock [get_clocks {spiclk}]  0.500 [get_ports {mosi_0}]
set_input_delay -add_delay -fall -min -clock [get_clocks {spiclk}]  0.200 [get_ports {mosi_0}]
set_input_delay -add_delay  -clock_fall -clock [get_clocks {spiclk}]  0.500 [get_ports {mosi_0}]


#**************************************************************
# Set Output Delay
#**************************************************************

set_output_delay -add_delay  -clock_fall -clock [get_clocks {clk_100m}]  0.100 [get_ports {miso_0}]


#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -asynchronous -group [get_clocks {clk_100m}] -group [get_clocks {spiclk}] 


#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

