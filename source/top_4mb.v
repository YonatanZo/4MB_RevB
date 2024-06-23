////////////////////////////////////////////////////
//	File			: top_4mb.v
//	Author			: Igor Dorman. tracePCB.
//	Date			: 25/10/2022
//	Description		: 4.M.B. Top File.
//	Revision		: 1.0
//	Hierarchy		: top_4mb
//	Last Update		: 12/01/2023 
////////////////////////////////////////////////////

module top_4mb(
	//System signals
    clk_100m,       // system clock
	clk_100m_1,
	//clk_1m,
    rst_n,      	// low active synchronous reset
	FPGA_rstn,
	//SPI INTERFACE 0
	mclk_0,      	// SPI clock
	mosi_0,     	// SPI serial data from master to slave
	miso_0,     	// SPI serial data from slave to master
	cs_00,     		// SPI chip select, active in low
	//SPI INTERFACE 1
	mclk_1,      	// SPI clock
	mosi_1,     	// SPI serial data from master to slave
	miso_1,     	// SPI serial data from slave to master
	cs_1,     		// SPI chip select, active in low
	cs_2,     		// SPI chip select, active in low
	cs_3,     		// SPI chip select, active in low
	cs_4,     		// SPI chip select, active in low
	CS_5,	//was tSP0 J14
	CS_6,	//was tSP1 K15
	CS_7,	//was tSP2 J16
	CS_8,	//was tSP3 J15
	Vf_CS,	//was M4brk T12
	BRf_CS,	//was M5brk T13
	//Incremental Encoders
	qc1a,
	qc1b,
	qc1i,
	qc2a,
	qc2b,
	qc2i,
	qc3a,
	qc3b,
	qc3i,
	qc4a,
	qc4b,
	qc4i,
	//SSI interface to Absolute Encoders
	ssi_d1,
	ssi_c1,
	ssi_d2,
	ssi_c2,
	ssi_d3,
	ssi_c3,
	ssi_d4,
	ssi_c4,
	ssi_d5,
	ssi_c5,
	//Draping Switch
	// btn1no,
	// btn1nc,
	//Tool Exch Switch
	btn2no,
	btn2nc,
	//Plunger Switch
	btn3no,
	btn3nc,
	//Diagnostic LEDs
	led1_1,
	led1_2,
	//Plinger LEDs
	led3_3,
	led3_2,
	led3_1,
	//Tool Exch LEDs
	led2_3,
	led2_2,
	led2_1,
	//Draping Switches
	lsw_2,
	lsw_1,
	//LEDs of Motor4
	led1m4,
	led2m4,
	led3m4,
	//nFault
	nfault1,
	nfault2,
	nfault3,
	nfault4,
	//
	droff1,
	droff2,
	droff3,
	droff4,
	//PWM of Motors
	pwm1,
	pwm2,
	pwm3,
	pwm4,
	//BRAKE of Motors
	brake1,
	brake2,
	brake3,
	brake4,
	//
	fgout1,
	fgout2,
	fgout3,
	fgout4,
	//ADC I2C
	f_sda, //was tSP4 H15
	f_sck, //was tSP5 H16
	

	//DIP Switches
	dipsw3,
	dipsw2,
	dipsw1,
	dipsw0,
	//
	tclk,
	//tsp0,
	//tsp1,
	//tsp2,
	//tsp3,
	//tsp4,
	//tsp5,
	tsp6,
	// 
	ain_1,
	ain_2,
	ain_3,
	ain_4,
	//CAN BUS
	// fcan_tx0,
	// fcan_rx0,
	// fcan_shdn,
	fcan_stb,
	//UART CH-0
	frx_0,
	ftx_0,
	frx_01,
	ftx_01,
	//UART CH-1
	frx_1,
	ftx_1,
	//
	//m4brk,
	//m5brk,
	//Spare IO Register
	spare0_io,
	spare1_io,
	io_led,
	//Fault Flages
	QC1Bf,  //connect to B15
	QC1if,  //connect to B16
	QC3if,  //connect to C14
	QC3Bf,  //connect to D14
	QC2Bf,  //connect to E14
	QC2if,  //connect to E15
	QC3Af,  //connect to E16
	QC2Af,  //connect to F14
	QC1Af,  //connect to G12
	QC4Af,	//was FCAN-Tx0 connect to P10
	QC4Bf,	//was FCAN-Rx0 connect to P11
	QC4if,	//was FCAN-shdn connect to R11
	flt_S_D2, //G14
	flt_S_D3, //G15
	flt_S_D4, //G16
	flt_S_D1,  //H12
	//Alerts 
	V_ALRT,	 //was BTN1nc N16
	BRK_ALRT //was BTN1no P16
);



//System signals
input	clk_100m;       
input	clk_100m_1;
//input	clk_1m;
input	rst_n; 
input	FPGA_rstn;  	
//SPI INTERFACE 0(slave)
input	mclk_0;      	
input	mosi_0;     	
output	miso_0;     	
input	cs_00;     		
//SPI INTERFACE 1(master)
output	mclk_1;      	
output	mosi_1;     	
input	miso_1;     	
output	cs_1;     		
output	cs_2;     		
output	cs_3;     		
output	cs_4;  
output	CS_5;	
output	CS_6;
output	CS_7;
output	CS_8;	
output	Vf_CS;	
output	BRf_CS;
//Incremental Encoders
input	qc1a;
input	qc1b;
input	qc1i;
input	qc2a;
input	qc2b;
input	qc2i;
input	qc3a;
input	qc3b;
input	qc3i;
input	qc4a;
input	qc4b;
input	qc4i;
//SSI interface to Absolute Encoders
input	ssi_d1;
output	ssi_c1;
input	ssi_d2;
output	ssi_c2;
input	ssi_d3;
output	ssi_c3;
input	ssi_d4;
output	ssi_c4;
input	ssi_d5;
output	ssi_c5;
//ADC I2C 
inout wire f_sda;
inout wire f_sck;
//ADC Alerts -TBD:connect to register
input	V_ALRT;
input	BRK_ALRT;
//Fault Flages -TBD:connect to register
input	QC1Bf;
input	QC1if;
input	QC3if;
input	QC3Bf;
input	QC2Bf;
input	QC2if; 
input	QC3Af; 
input	QC2Af;
input	QC1Af;
input	QC4Af;
input	QC4Bf;
input	QC4if;
input	flt_S_D2;
input	flt_S_D3;
input	flt_S_D4;
input	flt_S_D1;  
//Tool Exch Switch
input	btn2no;
input	btn2nc;
//Plunger Switch
input	btn3no;
input	btn3nc;
//Diagnostic LEDs
output reg	led1_1;
output	led1_2;
//Plinger LEDs
output	led3_3;
output	led3_2;
output	led3_1;
//Tool Exch LEDs
output	led2_3;
output	led2_2;
output	led2_1;
//Draping Switches
input	lsw_2;
input	lsw_1;
//LEDs of Motor4
output	led1m4;
output	led2m4;
output	led3m4;
//nFault
input	nfault1;
input	nfault2;
input	nfault3;
input	nfault4;
//
output	droff1;
output	droff2;
output	droff3;
output	droff4;
//PWM of Motors
output	pwm1;
output	pwm2;
output	pwm3;
output	pwm4;
//BRAKE of Motors
output	brake1;
output	brake2;
output	brake3;
output	brake4;
//
input	fgout1;
input	fgout2;
input	fgout3;
input	fgout4;
//DIP Switches
input	dipsw0;
input	dipsw1;
input	dipsw2;
input	dipsw3;
//
input	tclk;
// input	tsp0;
// input	tsp1;
// input	tsp2;
// input	tsp3;
// input	tsp4;
// input	tsp5;
input	tsp6;
// 
input	ain_1;
input	ain_2;
input	ain_3;
input	ain_4;
// //CAN BUS
// output	fcan_tx0;
// input	fcan_rx0;
// output	fcan_shdn;
output	fcan_stb;
//UART CH-0
input	frx_0;
output	ftx_0;
input	frx_01;
output	ftx_01;
//UART CH-1
input	frx_1;
output	ftx_1;
//
// input	m4brk;
// input	m5brk;
//Spare IO
output[23:0]	spare0_io;
input[16:0]		spare1_io;
output[6:0]		io_led;


//For Eval Board	
/*DE10
	output[31:0] hex1;//incr_enc_cnt_reg1;
	output[31:0] hex2;//incr_enc_cnt_reg1;
*/

`include  "parameters_4mb.v"
reg[31:0] M1_POS_reg;
reg[31:0] M2_POS_reg;
reg[31:0] M3_POS_reg;
reg[31:0] M1_ERR_reg;
reg[31:0] M2_ERR_reg;
reg[31:0] M3_ERR_reg;
reg ERR_sig;
reg WARN_sig;
reg[5:0] CRC_sig;
reg RDY_sig;
reg BUSY_sig;
wire		clk_100m;       
wire		clk_100m_1;
//wire		clk_1m;
wire 		rst_n;
reg			rst_n_syn;
reg[7:0]	rst_n_meta;
wire[23:0]	spare0_io;
wire[16:0]	spare1_io;
wire[31:0]	data_miso;
wire[31:0]	data_mosi;
wire[15:0] 	addr;
reg[31:0]	data_miso_reg;

//Rev B regs start
wire[31:0]	ADC_Alerts_reg;
wire[31:0]	Fault_Flages_reg;
reg[31:0]	ADC0_Voltage_A;
reg[31:0]	ADC0_Voltage_B;
reg[31:0]	ADC0_Voltage_C;
reg[31:0]	ADC0_Voltage_D;
reg[31:0]	ADC1_Voltage_A;
reg[31:0]	ADC1_Voltage_B;
reg[31:0]	ADC1_Voltage_C;
reg[31:0]	ADC1_Voltage_D;
wire[31:0]   ABS_ENC_CTRL_REG;
//Rev B regs end

wire[31:0]	incr_enc_cnt_reg1;
wire[31:0]	incr_enc_error_reg1;
wire[31:0]	incr_enc_def_ticks_reg1;
wire[31:0]	abs_enc_position_reg1;
wire[31:0]	motion_control_reg1;
wire[31:0]	pwm_cycle_reg1;
wire[31:0]	driver_feedback_reg1;
wire[31:0]	driver_control_reg1;

wire[31:0]	incr_enc_cnt_reg2;
wire[31:0]	incr_enc_error_reg2;
wire[31:0]	incr_enc_def_ticks_reg2;
wire[31:0]	abs_enc_position_reg2;
wire[31:0]	motion_control_reg2;
wire[31:0]	pwm_cycle_reg2;
wire[31:0]	driver_feedback_reg2;
wire[31:0]	driver_control_reg2;

wire[31:0]	incr_enc_cnt_reg3;
wire[31:0]	incr_enc_error_reg3;
wire[31:0]	incr_enc_def_ticks_reg3;
wire[31:0]	abs_enc_position_reg3;
wire[31:0]	motion_control_reg3;
wire[31:0]	pwm_cycle_reg3;
wire[31:0]	driver_feedback_reg3;
wire[31:0]	driver_control_reg3;

wire[31:0]	incr_enc_cnt_reg4;
wire[31:0]	incr_enc_error_reg4;
wire[31:0]	incr_enc_def_ticks_reg4;
wire[31:0]	abs_enc_position_reg4;
wire[31:0]	abs_enc_error_reg4;
wire[31:0]	motion_control_reg4;
wire[31:0]	pwm_cycle_reg4;
wire[31:0]	driver_feedback_reg4;
wire[31:0]	driver_control_reg4;

wire[31:0] 	ver_reg;
wire[31:0] 	rev_data_reg;
wire[31:0] 	dip_sw_reg;
wire[31:0] 	buttons_reg;
wire[31:0] 	buttons_led_reg;
wire[31:0] 	drape_sensor_reg;
wire[31:0]	spare0_io_reg;
wire[31:0]	spare1_io_reg;
wire		data_mosi_rdy; 
wire		addr_rdy;
wire		data_miso_rdy;
wire[3:0]	ssi_read_quntity_1;
wire[3:0]	ssi_read_quntity_2;
wire[3:0]	ssi_read_quntity_3;

wire	mclk_1;      	
wire	mosi_1;     		
wire	cs_1;     		
wire	cs_2;     		
wire	cs_3;     		
wire	cs_4;
wire	ssi_c5;

wire	led1m4;
wire	led2m4;
wire	led3m4;
wire	fcan_tx0;
wire	fcan_shdn;
wire	fcan_stb;
wire	ftx_0;
wire	ftx_01;
wire	ftx_1; 
wire Master_rstn;
wire[6:0]	io_led;
wire[7:0]	crc_err_cnt_1;
wire[1:0]	status_bits_1;
wire[7:0]	crc_err_cnt_2;
wire[1:0]	status_bits_2;
wire[7:0]	crc_err_cnt_3;
wire[1:0]	status_bits_3;
 
reg	old_ssi_d1;
wire	old_ssi_c1;
reg	old_ssi_d2;
wire	old_ssi_c2;
reg	old_ssi_d3;
wire	old_ssi_c3;
reg	biss_d1;
reg	biss_c1;
reg	biss_d2;
reg	biss_c2;
reg	biss_d3;
reg	biss_c3;
wire 	enc_sel;
reg ssi_c1_ff, ssi_c2_ff, ssi_c3_ff;


// wire[15:0] BRKs_1;
// wire[15:0] BRKs_2;
// wire[15:0] BRKs_3;
// wire[15:0] BRKs_4;
// wire[15:0] BRKs_5;
// wire[15:0] ILIM1;
// wire[15:0] ILIM2;
// wire[15:0] ILIM3;
wire[15:0] ILIM4;
wire[15:0] V32s;
wire[15:0] V24s;
wire[15:0] V12s;
wire[15:0] V5s;
wire[15:0] V3_3s;
wire[15:0] V2_5s;
wire[15:0] V1_2s;

/*DE10
assign hex1 = incr_enc_cnt_reg1;
assign hex2 = dip_sw_reg;
*/

always @(posedge clk_100m)
begin
	if (rst_n_meta!=8'hAD) 
	begin
		rst_n_meta<=rst_n_meta+ 1'b1;
	end
	
	if (rst_n_meta==8'hAA) 
	begin
		rst_n_syn<=1'b0;
	end 
	else 
	begin
		rst_n_syn<=1'b1;
	end
	
	if(!rst_n) 
	begin
		rst_n_meta<=8'hAA;
	end
end


assign ssi_c1 = ssi_c1_ff;
assign ssi_c2 = ssi_c2_ff;
assign ssi_c3 = ssi_c3_ff;
assign data_miso = data_miso_reg;

//Unused outputs

assign mclk_1 = 1'b1;      	
assign mosi_1 = 1'b1;     		
assign cs_1 = 1'b1;     		
assign cs_2 = 1'b1;     		
assign cs_3 = 1'b1;     		
assign cs_4 = 1'b1; 
assign CS_5 = 1'b1;	
assign CS_6 = 1'b1; 
assign CS_7 = 1'b1; 
assign CS_8 = 1'b1; 	
assign Vf_CS = 1'b1; 	
assign BRf_CS = 1'b1; 
assign ssi_c5 = 1'b1;
assign led1m4 = 1'b0;
assign led2m4 = 1'b0;
assign led3m4 = 1'b0;
assign fcan_tx0 = 1'b1;
assign fcan_shdn = 1'b1;
assign fcan_stb = 1'b1;
assign ftx_0 = 1'b1;
assign ftx_01 = 1'b1;
assign ftx_1 = 1'b1;
assign spare0_io = spare0_io_reg[23:0];
assign Master_rstn = FPGA_rstn & rst_n_syn;
assign enc_sel = 1'b1;//ABS_ENC_CTRL_REG[0]; TODO:change back!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



//Read Registers MUX
always @*
    case(addr)
	//////////////Rev B///////////////////////////
	ADDR_ADC_Alerts:
		data_miso_reg = ADC_Alerts_reg;
	ADDR_Fault_Flages_reg:
		data_miso_reg = Fault_Flages_reg;
	ADDR_ADC0_Voltage_A:
		data_miso_reg = ADC0_Voltage_A;
	ADDR_ADC0_Voltage_B:
		data_miso_reg = ADC0_Voltage_B;
	ADDR_ADC0_Voltage_C:
		data_miso_reg = ADC0_Voltage_C;
	ADDR_ADC0_Voltage_D:
		data_miso_reg = ADC0_Voltage_D;
	ADDR_ADC1_Voltage_A:
		data_miso_reg = ADC1_Voltage_A;
	ADDR_ADC1_Voltage_B:
		data_miso_reg = ADC1_Voltage_B;
	ADDR_ADC1_Voltage_C:
		data_miso_reg = ADC1_Voltage_C;
	ADDR_ADC1_Voltage_D:
		data_miso_reg = ADC1_Voltage_D;
	ADDR_ABS_ENC_CTRL:
		data_miso_reg = ABS_ENC_CTRL_REG;
	ADDR_RLS_POS_REG_0:
		data_miso_reg = M1_POS_reg;
	ADDR_RLS_POS_REG_1:
		data_miso_reg = M2_POS_reg;
	ADDR_RLS_POS_REG_2:
		data_miso_reg = M3_POS_reg;
	ADDR_RLS_ERR_REG_0:
		data_miso_reg = M1_ERR_reg;
	ADDR_RLS_ERR_REG_1:
		data_miso_reg = M2_ERR_reg;
	ADDR_RLS_ERR_REG_2:
		data_miso_reg = M3_ERR_reg;	
	/////////////////////////////////////////////
	ADDR_FPGA_VER:
			data_miso_reg = ver_reg;
		ADDR_FPGA_REV_DATA:
			data_miso_reg = rev_data_reg;
		ADDR_FPGA_DIP_SWITCH:
			data_miso_reg = dip_sw_reg;

		ADDR_FPGA_M1_INC:
			data_miso_reg = incr_enc_cnt_reg1;
		ADDR_FPGA_M1_INC_ERROR:
			data_miso_reg = incr_enc_error_reg1;
		ADDR_FPGA_M1_DEF_TICKS:
			data_miso_reg = incr_enc_def_ticks_reg1;
		ADDR_FPGA_M1_ABSOLUTE:
			// if (enc_sel)
			// begin
			// 	data_miso_reg ={6'b0,M1_POS_sig};
			// end
			// else
			// begin
				data_miso_reg = abs_enc_position_reg1;
			// end
		ADDR_FPGA_M1_MOTION_CONTROL:
			data_miso_reg = motion_control_reg1;	
		ADDR_FPGA_M1_PWM_CYCLE:
			data_miso_reg = pwm_cycle_reg1;		
		ADDR_FPGA_M1_FEEDBACK:
			data_miso_reg = driver_feedback_reg1;	
		ADDR_FPGA_M1_DRIVER_CONTROL:
			data_miso_reg = driver_control_reg1;
		ADDR_FPGA_M2_INC:
			data_miso_reg = incr_enc_cnt_reg2;
		ADDR_FPGA_M2_INC_ERROR:
			data_miso_reg = incr_enc_error_reg2;
		ADDR_FPGA_M2_DEF_TICKS:
			data_miso_reg = incr_enc_def_ticks_reg2;
		ADDR_FPGA_M2_ABSOLUTE:
			// if (enc_sel)
			// begin
			// 	data_miso_reg ={6'b0,M2_POS_sig} ;
			// end
			// else
			// begin
				data_miso_reg = abs_enc_position_reg2;
			// end
		ADDR_FPGA_M2_MOTION_CONTROL:
			data_miso_reg = motion_control_reg2;	
		ADDR_FPGA_M2_PWM_CYCLE:
			data_miso_reg = pwm_cycle_reg2;		
		ADDR_FPGA_M2_FEEDBACK:
			data_miso_reg = driver_feedback_reg2;	
		ADDR_FPGA_M2_DRIVER_CONTROL:
			data_miso_reg = driver_control_reg2;

		ADDR_FPGA_M3_INC:
			data_miso_reg = incr_enc_cnt_reg3;
		ADDR_FPGA_M3_INC_ERROR:
			data_miso_reg = incr_enc_error_reg3;
		ADDR_FPGA_M3_DEF_TICKS:
			data_miso_reg = incr_enc_def_ticks_reg3;
		ADDR_FPGA_M3_ABSOLUTE:
			// if (enc_sel)
			// begin
			// 	data_miso_reg = {6'b0,M3_POS_sig};
			// end
			// else
			// begin
				data_miso_reg = abs_enc_position_reg3;
			// end
		ADDR_FPGA_M3_MOTION_CONTROL:
			data_miso_reg = motion_control_reg3;	
		ADDR_FPGA_M3_PWM_CYCLE:
			data_miso_reg = pwm_cycle_reg3;		
		ADDR_FPGA_M3_FEEDBACK:
			data_miso_reg = driver_feedback_reg3;	
		ADDR_FPGA_M3_DRIVER_CONTROL:
			data_miso_reg = driver_control_reg3;
			
		ADDR_FPGA_M4_INC:
			data_miso_reg = incr_enc_cnt_reg4;
		ADDR_FPGA_M4_INC_ERROR:
			data_miso_reg = incr_enc_error_reg4;
		ADDR_FPGA_M4_DEF_TICKS:
			data_miso_reg = incr_enc_def_ticks_reg4;
		ADDR_FPGA_M4_ABSOLUTE:
			data_miso_reg = abs_enc_position_reg4;
		ADDR_FPGA_M4_ABSOLUTE_ERROR:
			data_miso_reg = abs_enc_error_reg4;
		ADDR_FPGA_M4_MOTION_CONTROL:
			data_miso_reg = motion_control_reg4;	
		ADDR_FPGA_M4_PWM_CYCLE:
			data_miso_reg = pwm_cycle_reg4;		
		ADDR_FPGA_M4_FEEDBACK:
			data_miso_reg = driver_feedback_reg4;	
		ADDR_FPGA_M4_DRIVER_CONTROL:
			data_miso_reg = driver_control_reg4;
			
		ADDR_FPGA_BUTTONS:
			data_miso_reg = buttons_reg;
		ADDR_FPGA_BUTTONS_LED:
			data_miso_reg = buttons_led_reg;
		ADDR_FPGA_DRAPE_SWITCH:
			data_miso_reg = drape_sensor_reg;
		ADDR_FPGA_SPARE0_IO:
			data_miso_reg = spare0_io_reg;
		ADDR_FPGA_SPARE1_IO:
			data_miso_reg = spare1_io_reg;
		ADDR_FPGA_DIAG_LEDS:
			data_miso_reg = {23'b0,io_led,led1_2,led1_2};
		ADDR_FPGA_M1_3_ABS_ENC_COUNT:
			data_miso_reg = {8'b0,ssi_read_quntity_3,ssi_read_quntity_2,ssi_read_quntity_1};	

		ADDR_FPGA_M1_3_ABS_ENC_STATUS:
			data_miso_reg = {status_bits_1,status_bits_2,status_bits_3,2'b0,
							crc_err_cnt_1,crc_err_cnt_2,crc_err_cnt_3};			
		default:
			data_miso_reg = 32'hFFFFFFFF;
	endcase
///////////////////LED Blinking Proccess 
    localparam integer CLOCK_FREQ = 100_000_000;  // 100MHz
    localparam integer BLINK_FREQ = 5;            // 5Hz
    localparam integer COUNT_MAX = (CLOCK_FREQ / (2 * BLINK_FREQ)) - 1;

    reg [24:0] counter;   // Counter register (25 bits to count up to 20,000,000)

	
    always @(posedge clk_100m or negedge Master_rstn) begin
        if (!Master_rstn) begin
            counter <= 0;
            led1_1 <= 0;
        end else begin
            if (counter >= COUNT_MAX) begin
                counter <= 0;
                led1_1 <= ~led1_1;  // Toggle LED
            end else begin
                counter <= counter + 1;
            end
        end
    end


	always @ (enc_sel) begin
		
		// if (enc_sel) begin
			ssi_c1_ff <= biss_c1;
			ssi_c2_ff <= biss_c2;
			ssi_c3_ff <= biss_c3;
			biss_d1 <= ssi_d1;
			biss_d2 <= ssi_d2;
			biss_d3 <= ssi_d3;
		// end else begin
		// 	ssi_c1_ff <= old_ssi_c1;  // Retain previous value, caution: might infer latch if not handled outside
		// 	ssi_c2_ff <= old_ssi_c2;
		// 	ssi_c3_ff <= old_ssi_c3;
		// 	old_ssi_d1 <= ssi_d1;
		// 	old_ssi_d2 <= ssi_d2;
		// 	old_ssi_d3 <= ssi_d3;
		// end
	end
// 	adc_manger adc_manger_inst
// (
// 	.clk(clk_100m) ,	// input  clk_sig
// 	.reset_n(Master_rstn) ,	// input  reset_n_sig
// 	.scl(f_sck) ,	// inout  scl_sig
// 	.sda(f_sda) ,	// inout  sda_sig
// 	.ADC0_Voltage_A(ADC0_Voltage_A) ,	// output [31:0] ADC0_Voltage_A_sig
// 	.ADC0_Voltage_B(ADC0_Voltage_B) ,	// output [31:0] ADC0_Voltage_B_sig
// 	.ADC0_Voltage_C(ADC0_Voltage_C) ,	// output [31:0] ADC0_Voltage_C_sig
// 	.ADC0_Voltage_D(ADC0_Voltage_D) ,	// output [31:0] ADC0_Voltage_D_sig
// 	.ADC1_Voltage_A(ADC1_Voltage_A) ,	// output [31:0] ADC1_Voltage_A_sig
// 	.ADC1_Voltage_B(ADC1_Voltage_B) ,	// output [31:0] ADC1_Voltage_B_sig
// 	.ADC1_Voltage_C(ADC1_Voltage_C) ,	// output [31:0] ADC1_Voltage_C_sig
// 	.ADC1_Voltage_D(ADC1_Voltage_D) 	// output [31:0] ADC1_Voltage_D_sig
// );

	// assign f_sda = 1'bz;   
	// assign f_sck = 1'bz;   

	i2c_top brakes_currnt_adc  //Brakes cur mes
	(
		.clk(clk_100m) ,	// input  clk_sig
		.reset_n(Master_rstn) ,	// input  reset_n_sig
		.scl(f_sck) ,	// inout  scl_sig
		.sda(f_sda) ,	// inout  sda_sig
		.START(1'b1) ,
		.AIN0(ADC0_Voltage_A[15:0]) ,	// BRKs_1
		.AIN1(ADC0_Voltage_A[31:16]) ,	// BRKs_2
		.AIN2(ADC0_Voltage_B[15:0]) ,	// BRKs_3
		.AIN3(ADC0_Voltage_B[31:16]) ,	// BRKs_4
		.AIN4(ADC0_Voltage_C[15:0]) ,	// BRKs_5
		.AIN5(ADC0_Voltage_C[31:16]) ,	// ILIM1
		.AIN6(ADC0_Voltage_D[15:0]) ,	// ILIM2
		.AIN7(ADC0_Voltage_D[31:16])	// ILIM3
	);
	
	defparam brakes_currnt_adc.DEV_ID =7'b0010101; //7'b0010010;
	
	// i2c_top analog_voltage_adc  
	// (
	// 	.clk(clk_100m) ,	// input  clk_sig
	// 	.reset_n(Master_rstn) ,	// input  reset_n_sig
	// 	.scl(f_sda) ,	// inout  scl_sig
	// 	.sda(f_sda) ,	// inout  sda_sig
	// 	.START(1'b1) ,
	// 	.AIN0(ADC1_Voltage_A[15:0]) ,	// 32s
	// 	.AIN1(ADC1_Voltage_A[31:16]) ,	// 24s
	// 	.AIN2(ADC1_Voltage_B[15:0]) ,	// 12s
	// 	.AIN3(ADC1_Voltage_B[31:16]) ,		// 5s
	// 	.AIN4(ADC1_Voltage_C[15:0]) ,	// 3_3s
	// 	.AIN5(ADC1_Voltage_C[31:16]) ,	// 2_5s
	// 	.AIN6(ADC1_Voltage_D[15:0]) ,	// 1_2s
	// 	.AIN7(ADC1_Voltage_D[31:16]) 	// ILIM4
	// );


	// defparam analog_voltage_adc.DEV_ID = 7'b0010101;
	


	RLS_Top RLS_Top_inst
	(
		.clk(clk_100m) ,	// input  clk_sig
		.reset_n(Master_rstn) ,	// input  reset_n_sig
		.RLS_MA_0(biss_c1) ,	// output  RLS_MA_0_sig
		.RLS_MA_1(biss_c2) ,	// output  RLS_MA_1_sig
		.RLS_MA_2(biss_c3) ,	// output  RLS_MA_2_sig
		.RLS_SLO_0(biss_d1) ,	// input  RLS_SLO_0_sig
		.RLS_SLO_1(biss_d2) ,	// input  RLS_SLO_1_sig
		.RLS_SLO_2(biss_d3) ,	// input  RLS_SLO_2_sig
		.POS_REG_0(M1_POS_reg) ,	// output [25:0] POS_0_sig
		.POS_REG_1(M2_POS_reg) ,	// output [25:0] POS_1_sig
		.POS_REG_2(M3_POS_reg) ,	// output [25:0] POS_2_sig
		.ERR_REG_0(M1_ERR_reg) ,
		.ERR_REG_1(M2_ERR_reg) ,
		.ERR_REG_2(M3_ERR_reg) 
	);
	
	defparam RLS_Top_inst.input_clk = 100000000;
	defparam RLS_Top_inst.bus_clk = 1000000;

//SPI insertion  
	spi_if spi_4mb(  //spi_if
    .clk_100m(clk_100m),       	
    .rst_n_syn(Master_rstn),      
	.sclk(mclk_0),
	.mosi(mosi_0),
	.miso_t(miso_0),
	.cs_n(cs_00),
    .data_miso(data_miso),    
    .data_mosi(data_mosi),     
    .data_mosi_rdy(data_mosi_rdy), 
	.addr(addr),
	.addr_rdy(addr_rdy),
	.data_miso_rdy(data_miso_rdy)
);

//REGISRES insertion  
registers_4mb registers_4mb(
    .clk_100m(clk_100m),       	
    .rst_n_syn(Master_rstn), 
	//.clk_1m(clk_1m),
	//Rev B regs start
	.ADC_Alerts_reg(ADC_Alerts_reg),
	.V_ALRT(V_ALRT),
	.BRK_ALRT(BRK_ALRT),
	.Fault_Flages_reg(Fault_Flages_reg),
	.QC1Bf(QC1Bf),
	.QC1if(QC1if),
	.QC3if(QC3if),
	.QC3Bf(QC3Bf),
	.QC2Bf(QC2Bf),
	.QC2if(QC2if),
	.QC3Af(QC3Af),
	.QC2Af(QC2Af),
	.QC1Af(QC1Af),
	.QC4Af(QC4Af),
	.QC4Bf(QC4Bf),
	.QC4if(QC4if),
	.flt_S_D2(flt_S_D2),
	.flt_S_D3(flt_S_D3),
	.flt_S_D4(flt_S_D4),
	.flt_S_D1(flt_S_D1),
	.ABS_ENC_CTRL_REG(ABS_ENC_CTRL_REG),
	//Rev B regs end
    .data_mosi(data_mosi),     
    .data_mosi_rdy(data_mosi_rdy), 
	.addr(addr),
	.btn1no(btn1no),
	.btn1nc(btn1nc),
	.btn2no(btn2no),
	.btn2nc(btn2nc),
	.btn3no(btn3no),
	.btn3nc(btn3nc),
	// .led1_1(led1_1),
	.led1_2(led1_2),
	.led2_1(led2_1),
	.led2_2(led2_2),
	.led2_3(led2_3),
	.led3_1(led3_1),
	.led3_2(led3_2),
	.led3_3(led3_3),
	.lsw_2(lsw_2),
	.lsw_1(lsw_1),
	.dipsw3(dipsw3),
	.dipsw2(dipsw2),
	.dipsw1(dipsw1),
	.dipsw0(dipsw0),
	.spare1_io(spare1_io),
	.ver_reg(ver_reg),
	.rev_data_reg(rev_data_reg),
	.dip_sw_reg(dip_sw_reg),
	.buttons_reg(buttons_reg),
	.buttons_led_reg(buttons_led_reg),
	.drape_sensor_reg(drape_sensor_reg),
	.spare0_io_reg(spare0_io_reg),
	.spare1_io_reg(spare1_io_reg),
	.io_led(io_led)
);

//Motor Control Register insertion 
motor_control  
#(ADDR_FPGA_M1_INC,ADDR_FPGA_M1_INC_ERROR,ADDR_FPGA_M1_DEF_TICKS,
	ADDR_FPGA_M1_ABSOLUTE,ADDR_FPGA_M1_MOTION_CONTROL,
	ADDR_FPGA_M1_PWM_CYCLE,ADDR_FPGA_M1_FEEDBACK,ADDR_FPGA_M1_DRIVER_CONTROL,
	IEF3_DEF_TICKS,M1_3_ABS_DATA_BITS,M1_3_CLOCK_PERIOD,M1_3_READ_PERIOD)
motor1_control(
    .clk_100m(clk_100m),       	
    .rst_n_syn(Master_rstn), 
	//.clk_1m(clk_1m),
    .data_mosi(data_mosi),     
    .data_mosi_rdy(data_mosi_rdy), 
	.addr(addr),
	.qca(qc1a),
	.qcb(qc1b),
	.qci(qc1i),
	.ssi_d(old_ssi_d1),
	.ssi_c(old_ssi_c1),
	.nfault(nfault1),
	.droff(droff1),
	.pwm(pwm1),
	.brake(brake1),
	.fgout(fgout1),
	.incr_enc_cnt_reg(incr_enc_cnt_reg1),
	.incr_enc_error_reg(incr_enc_error_reg1),
	.incr_enc_def_ticks_reg(incr_enc_def_ticks_reg1),
	.abs_enc_position_reg(abs_enc_position_reg1),
	.motion_control_reg(motion_control_reg1),
	.pwm_cycle_reg(pwm_cycle_reg1),
	.driver_feedback_reg(driver_feedback_reg1),
	.driver_control_reg(driver_control_reg1),
	.ssi_read_quntity(ssi_read_quntity_1),
	.mosi_status(data_mosi[31:30]),
	.crc_err_cnt(crc_err_cnt_1),
	.status_bits(status_bits_1)
);

motor_control  
#(ADDR_FPGA_M2_INC,ADDR_FPGA_M2_INC_ERROR,ADDR_FPGA_M2_DEF_TICKS,
	ADDR_FPGA_M2_ABSOLUTE,ADDR_FPGA_M2_MOTION_CONTROL,
	ADDR_FPGA_M2_PWM_CYCLE,ADDR_FPGA_M2_FEEDBACK,ADDR_FPGA_M2_DRIVER_CONTROL,
	IEF3_DEF_TICKS,M1_3_ABS_DATA_BITS,M1_3_CLOCK_PERIOD,M1_3_READ_PERIOD)//XMARS_CLOCK_PERIOD?,XMARS_READ_PERIOD?
motor2_control(
    .clk_100m(clk_100m),       	
    .rst_n_syn(Master_rstn), 
	//.clk_1m(clk_1m),
    .data_mosi(data_mosi),     
    .data_mosi_rdy(data_mosi_rdy), 
	.addr(addr),
	.qca(qc2a),
	.qcb(qc2b),
	.qci(qc2i),
	.ssi_d(old_ssi_d2),
	.ssi_c(old_ssi_c2),
	.nfault(nfault2),
	.droff(droff2),
	.pwm(pwm2),
	.brake(brake2),
	.fgout(fgout2),
	.incr_enc_cnt_reg(incr_enc_cnt_reg2),
	.incr_enc_error_reg(incr_enc_error_reg2),
	.incr_enc_def_ticks_reg(incr_enc_def_ticks_reg2),
	.abs_enc_position_reg(abs_enc_position_reg2),
	.motion_control_reg(motion_control_reg2),
	.pwm_cycle_reg(pwm_cycle_reg2),
	.driver_feedback_reg(driver_feedback_reg2),
	.driver_control_reg(driver_control_reg2),
	.ssi_read_quntity(ssi_read_quntity_2),
	.mosi_status(data_mosi[29:28]),
	.crc_err_cnt(crc_err_cnt_2),
	.status_bits(status_bits_2)
);

motor_control  
#(ADDR_FPGA_M3_INC,ADDR_FPGA_M3_INC_ERROR,ADDR_FPGA_M3_DEF_TICKS,
	ADDR_FPGA_M3_ABSOLUTE,ADDR_FPGA_M3_MOTION_CONTROL,
	ADDR_FPGA_M3_PWM_CYCLE,ADDR_FPGA_M3_FEEDBACK,ADDR_FPGA_M3_DRIVER_CONTROL,
	IEF3_DEF_TICKS,M1_3_ABS_DATA_BITS,M1_3_CLOCK_PERIOD,M1_3_READ_PERIOD)
motor3_control(
    .clk_100m(clk_100m),       	
    .rst_n_syn(Master_rstn), 
	//.clk_1m(clk_1m),
    .data_mosi(data_mosi),     
    .data_mosi_rdy(data_mosi_rdy), 
	.addr(addr),
	.qca(qc3a),
	.qcb(qc3b),
	.qci(qc3i),
	.ssi_d(old_ssi_d3),
	.ssi_c(old_ssi_c3),
	.nfault(nfault3),
	.droff(droff3),
	.pwm(pwm3),
	.brake(brake3),
	.fgout(fgout3),
	.incr_enc_cnt_reg(incr_enc_cnt_reg3),
	.incr_enc_error_reg(incr_enc_error_reg3),
	.incr_enc_def_ticks_reg(incr_enc_def_ticks_reg3),
	.abs_enc_position_reg(abs_enc_position_reg3),
	.motion_control_reg(motion_control_reg3),
	.pwm_cycle_reg(pwm_cycle_reg3),
	.driver_feedback_reg(driver_feedback_reg3),
	.driver_control_reg(driver_control_reg3),
	.ssi_read_quntity(ssi_read_quntity_3),
	.mosi_status(data_mosi[27:26]),
	.crc_err_cnt(crc_err_cnt_3),
	.status_bits(status_bits_3)
);

motor4_control  
#(ADDR_FPGA_M4_INC,ADDR_FPGA_M4_INC_ERROR,ADDR_FPGA_M4_DEF_TICKS,
	ADDR_FPGA_M4_ABSOLUTE,ADDR_FPGA_M4_MOTION_CONTROL,
	ADDR_FPGA_M4_PWM_CYCLE,ADDR_FPGA_M4_FEEDBACK,ADDR_FPGA_M4_DRIVER_CONTROL,
	FLUX_DEF_TICKS,FLUX_DATA_BITS,FLUX_CLOCK_PERIOD,FLUX_READ_PERIOD)
motor4_control(
    .clk_100m(clk_100m),       	
    .rst_n_syn(Master_rstn), 
	//.clk_1m(clk_1m),
    .data_mosi(data_mosi),     
    .data_mosi_rdy(data_mosi_rdy), 
	.addr(addr),
	.qca(qc4a),
	.qcb(qc4b),
	.qci(qc4i),
	.ssi_d(ssi_d4),
	.ssi_c(ssi_c4),
	.nfault(nfault4),
	.droff(droff4),
	.pwm(pwm4),
	.brake(brake4),
	.fgout(fgout4),
	.incr_enc_cnt_reg(incr_enc_cnt_reg4),
	.incr_enc_error_reg(incr_enc_error_reg4),
	.incr_enc_def_ticks_reg(incr_enc_def_ticks_reg4),
	.abs_enc_position_reg(abs_enc_position_reg4),
	.abs_enc_error_reg(abs_enc_error_reg4),
	.motion_control_reg(motion_control_reg4),
	.pwm_cycle_reg(pwm_cycle_reg4),
	.driver_feedback_reg(driver_feedback_reg4),
	.driver_control_reg(driver_control_reg4)
);



endmodule	

