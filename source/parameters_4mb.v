//////////////////////////////////////////////////////
//  File        : parameters_4mb.v                        
//  Author      : Igor Dorman. tracePCB                            
//  Date        : 30/08/2022
//  Description : Global Parameters of the 4.M.B.           
//  Revision    : 1.0  
//	Last Update	: 31/05/2023                                    
///////////////////////////////////////////////////////

//`define ESTOP_CIRCUIT;
//`define DE10;

//REVISION
parameter FPGA_MAJOR_VER	= 8'h02;
parameter FPGA_REV		= 8'h01;
parameter FPGA_REV_YEAR		= 8'h18;
parameter FPGA_REV_MONTH	= 8'h05;
parameter FPGA_REV_DAY		= 8'h0e;			
parameter FPGA_REV_HOUR		= 8'h0c;

// SPI packet Lenght
parameter SPI_COM_LEN = 8;
parameter SPI_ADDR_LEN = SPI_COM_LEN + 16;
parameter SPI_DATA_LEN = SPI_ADDR_LEN + 32;

//SPI COMMANDS
parameter WRITE_COM		= 8'h0A;	// Write Command(0A).
parameter READ_COM		= 8'h0F;	// Read Command(0F).
parameter WRITE_MODE	= 2'b00;	// Write Command(0A).
parameter READ_MODE		= 2'b01;	// Read Command(0F).
parameter UNDEF_MODE	= 2'b11;	// Undefined command. Write Cycle without saving result.

//M1-M3 parameters
parameter IEF3_DEF_TICKS		= 4096;//32'h00001000;	// IEF3-4096L - Default Incremental encoder ticks(resolution).
//parameter XMARS_DATA_BITS		= 32;					// xMars Absolute Encoder data bits(Total 32 bits, Position 24 bits).
parameter M1_3_ABS_DATA_BITS	= 44;		//Flux GMI-LINEAR 1xfirst clock where SDATA stays on 1,1xACK,1xSTART,1xCDS,
											//32xPosition bits. MSB first,2xStatus bits,6xCRC.
parameter M1_3_CLOCK_PERIOD		= 25;		//Flux GMI-LIN  BiSS Clock period(maximum 25=250nSec(4MHz), 100=1us(1MHz)).
parameter M1_3_READ_PERIOD		= 15000;	//Flux GMI-LIN BiSS Data Read period(1000=10uSec,5000=50uSec).
//M4 parameters
parameter FLUX_DEF_TICKS		= 16384;	// FLUX Default Incremental encoder ticks(resolution).
parameter FLUX_DATA_BITS		= 28;		// FLUX SSI Encoder data bits(Total 28 bits, Position 19 bits).
parameter FLUX_CLOCK_PERIOD		= 50;		// Flux SSI Clock period(1us).
parameter FLUX_READ_PERIOD		= 10000;	// FLUX SSI Data Read period(5000=50uSec).


parameter MOTOR_PWM_MAX_FREQ	= 500;			// maximum frequensy of motor's PWM(500x10nsec = 5usec(200 kHz))

parameter ENCODER_DEB_TIME		= 3;//5000000;		//Debounce time for incremental encoders. 5000000 = 5ms

// Addreses of FPGA rgisters
parameter ADDR_FPGA_VER 				= 16'h0000;
parameter ADDR_FPGA_REV_DATA			= 16'h0001;
parameter ADDR_FPGA_DIP_SWITCH 			= 16'h0002;
parameter ADDR_FPGA_M1_INC				= 16'h0003;
parameter ADDR_FPGA_M1_INC_ERROR		= 16'h0004;
parameter ADDR_FPGA_M1_DEF_TICKS		= 16'h0005;
parameter ADDR_FPGA_M1_ABSOLUTE			= 16'h0006;
parameter ADDR_FPGA_M1_MOTION_CONTROL	= 16'h0007;
parameter ADDR_FPGA_M1_PWM_CYCLE		= 16'h0008;
parameter ADDR_FPGA_M1_FEEDBACK			= 16'h0009;
parameter ADDR_FPGA_M1_DRIVER_CONTROL	= 16'h000A;
parameter ADDR_FPGA_M2_INC				= 16'h000B;
parameter ADDR_FPGA_M2_INC_ERROR		= 16'h000C;
parameter ADDR_FPGA_M2_DEF_TICKS		= 16'h000D;
parameter ADDR_FPGA_M2_ABSOLUTE			= 16'h000E;
parameter ADDR_FPGA_M2_MOTION_CONTROL	= 16'h000F;
parameter ADDR_FPGA_M2_PWM_CYCLE		= 16'h0010;
parameter ADDR_FPGA_M2_FEEDBACK			= 16'h0011;
parameter ADDR_FPGA_M2_DRIVER_CONTROL	= 16'h0012;
parameter ADDR_FPGA_M3_INC				= 16'h0013;
parameter ADDR_FPGA_M3_INC_ERROR		= 16'h0014;
parameter ADDR_FPGA_M3_DEF_TICKS		= 16'h0015;
parameter ADDR_FPGA_M3_ABSOLUTE			= 16'h0016;
parameter ADDR_FPGA_M3_MOTION_CONTROL	= 16'h0017;
parameter ADDR_FPGA_M3_PWM_CYCLE		= 16'h0018;
parameter ADDR_FPGA_M3_FEEDBACK			= 16'h0019;
parameter ADDR_FPGA_M3_DRIVER_CONTROL	= 16'h001A;
parameter ADDR_FPGA_M4_INC				= 16'h001B;
parameter ADDR_FPGA_M4_INC_ERROR		= 16'h001C;
parameter ADDR_FPGA_M4_DEF_TICKS		= 16'h001D;
parameter ADDR_FPGA_M4_ABSOLUTE			= 16'h001E;
parameter ADDR_FPGA_M4_ABSOLUTE_ERROR	= 16'h001F;
parameter ADDR_FPGA_M4_MOTION_CONTROL	= 16'h0020;
parameter ADDR_FPGA_M4_PWM_CYCLE		= 16'h0021;
parameter ADDR_FPGA_M4_FEEDBACK			= 16'h0022;
parameter ADDR_FPGA_M4_DRIVER_CONTROL	= 16'h0023;
parameter ADDR_FPGA_SPARE0_IO	 		= 16'h0024;
parameter ADDR_FPGA_SPARE1_IO	 		= 16'h0025;
parameter ADDR_FPGA_TEENSY_SPARE		= 16'h0026;
parameter ADDR_FPGA_BUTTONS				= 16'h0027;
parameter ADDR_FPGA_BUTTONS_LED			= 16'h0028;
parameter ADDR_FPGA_DRAPE_SWITCH		= 16'h0029;
parameter ADDR_FPGA_DIAG_LEDS			= 16'h002A;
parameter ADDR_FPGA_M1_3_ABS_ENC_COUNT	= 16'h002B;
parameter ADDR_FPGA_M1_3_ABS_ENC_STATUS	= 16'h002C;
parameter ADDR_ADC_Alerts 				= 16'h002d;
parameter ADDR_Fault_Flages_reg 		= 16'h002e;
parameter ADDR_ADC_Voltage_A				= 16'h002f;
parameter ADDR_ADC_Voltage_B				= 16'h0030;
parameter ADDR_ADC_Voltage_C				= 16'h0031;
parameter ADDR_ADC_Voltage_D				= 16'h0032;
parameter ADDR_ABS_ENC_CTRL				= 16'h0033;

parameter NUM_REG	= 44;	//Number of RCB Registers see above





	




