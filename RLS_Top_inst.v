// Copyright (C) 2023  Intel Corporation. All rights reserved.
// Your use of Intel Corporation's design tools, logic functions 
// and other software and tools, and any partner logic 
// functions, and any output files from any of the foregoing 
// (including device programming or simulation files), and any 
// associated documentation or information are expressly subject 
// to the terms and conditions of the Intel Program License 
// Subscription Agreement, the Intel Quartus Prime License Agreement,
// the Intel FPGA IP License Agreement, or other applicable license
// agreement, including, without limitation, that your use is for
// the sole purpose of programming logic devices manufactured by
// Intel and sold by Intel or its authorized distributors.  Please
// refer to the applicable agreement for further details, at
// https://fpgasoftware.intel.com/eula.


// Generated by Quartus Prime Version 22.1 (Build Build 922 07/20/2023)
// Created on Sun May 19 15:42:52 2024

RLS_Top RLS_Top_inst
(
	.clk(clk_sig) ,	// input  clk_sig
	.reset_n(reset_n_sig) ,	// input  reset_n_sig
	.RLS_MA_0(RLS_MA_0_sig) ,	// output  RLS_MA_0_sig
	.RLS_MA_1(RLS_MA_1_sig) ,	// output  RLS_MA_1_sig
	.RLS_MA_2(RLS_MA_2_sig) ,	// output  RLS_MA_2_sig
	.RLS_SLO_0(RLS_SLO_0_sig) ,	// input  RLS_SLO_0_sig
	.RLS_SLO_1(RLS_SLO_1_sig) ,	// input  RLS_SLO_1_sig
	.RLS_SLO_2(RLS_SLO_2_sig) ,	// input  RLS_SLO_2_sig
	.POS_0(POS_0_sig) ,	// output [25:0] POS_0_sig
	.POS_1(POS_1_sig) ,	// output [25:0] POS_1_sig
	.POS_2(POS_2_sig) ,	// output [25:0] POS_2_sig
	.ERR_0(ERR_0_sig) ,	// output [15:0] ERR_0_sig
	.ERR_1(ERR_1_sig) ,	// output [15:0] ERR_1_sig
	.ERR_2(ERR_2_sig) ,	// output [15:0] ERR_2_sig
	.WARN_0(WARN_0_sig) ,	// output [15:0] WARN_0_sig
	.WARN_1(WARN_1_sig) ,	// output [15:0] WARN_1_sig
	.WARN_2(WARN_2_sig) ,	// output [15:0] WARN_2_sig
	.CRC_0(CRC_0_sig) ,	// output [15:0] CRC_0_sig
	.CRC_1(CRC_1_sig) ,	// output [15:0] CRC_1_sig
	.CRC_2(CRC_2_sig) 	// output [15:0] CRC_2_sig
);

defparam RLS_Top_inst.input_clk = 100000000;
defparam RLS_Top_inst.bus_clk = 1000000;