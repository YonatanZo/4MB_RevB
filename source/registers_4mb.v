/////////////////////////////////////////////////////////
//	File			: registers_4mb.v
//	Author			: Igor Dorman. tracePCB.
//	Date			: 25/10/2022
//	Description		: RCB Registers.
//	Revision		: 1.0
//	Hierarchy		: top_4mb <- registers_4mb
//	Last Update		: 26/10/2022 
//////////////////////////////////////////////////////////

module registers_4mb(
	//System signals
    clk_100m,       	// system clock
    rst_n_syn,      	// low active synchronous reset
	//clk_1m, 
	//Internal signls
    data_mosi,		// received data from SPI master
    data_mosi_rdy,	// when 1, received data is valid
	addr,			// received data from SPI master
	//Draping Switch
	btn1no,
	btn1nc,
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
	//DIP Switches
	dipsw3,
	dipsw2,
	dipsw1,
	dipsw0,
	spare1_io,
	ver_reg,
	rev_data_reg,
	dip_sw_reg,
	buttons_reg,
	buttons_led_reg,
	drape_sensor_reg,
	spare0_io_reg,
	spare1_io_reg,
	io_led
);
	
	
	
input 		clk_100m; 
input 		rst_n_syn; 
//input		clk_1m; 
input[31:0]	data_mosi;
input		data_mosi_rdy;
input[15:0]	addr;
//Draping Switch
input	btn1no;
input	btn1nc;
//Tool Exch Switch
input	btn2no;
input	btn2nc;
	//Plunger Switch
input	btn3no;
input	btn3nc;
//Diagnostic LEDs
output	led1_1;
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
//DIP Switches
input	dipsw3;
input	dipsw2;
input	dipsw1;
input	dipsw0;

input[16:0]		spare1_io;

output[31:0] 	ver_reg;
output[31:0] 	rev_data_reg;
output[31:0] 	dip_sw_reg;
output[31:0] 	buttons_reg;
output[31:0] 	buttons_led_reg;
output[31:0] 	drape_sensor_reg;
output[31:0]	spare0_io_reg;
output[31:0]	spare1_io_reg;
output[6:0]		io_led;

`include  "parameters_4mb.v"


reg[31:0] 	ver_reg;
reg[31:0] 	rev_data_reg;
reg[31:0] 	dip_sw_reg;
reg[31:0] 	buttons_reg;
reg[5:0] 	buttons_meta;
reg[31:0] 	buttons_led_reg;
reg[31:0] 	drape_sensor_reg;
reg[1:0] 	drape_sensor_meta;

reg[31:0] 	diagnostic_led_reg;
wire[6:0]	io_led;
reg[31:0]	spare0_io_reg;
reg[31:0]	spare1_io_reg;
reg[16:0]	spare1_io_meta;

assign {led3_3,led3_2,led3_1,led2_3,led2_2,led2_1} = {buttons_led_reg[6:4],buttons_led_reg[2:0]};
assign {io_led,led1_2,led1_1} = diagnostic_led_reg[8:0];


always @(posedge clk_100m, negedge rst_n_syn)
	if(!rst_n_syn)
	begin
		ver_reg <= {16'b0,FPGA_MAJOR_VER,FPGA_REV};
		rev_data_reg <= {FPGA_REV_YEAR,FPGA_REV_MONTH,FPGA_REV_DAY,FPGA_REV_HOUR};
		dip_sw_reg <= 32'b0;
		buttons_reg <= 32'b0;
		buttons_meta <= 6'b0;
		drape_sensor_reg <= 32'b0;
		drape_sensor_meta <= 2'b0;
		spare1_io_reg <= 32'b0;
		spare1_io_meta <= 16'b0;
		buttons_led_reg <= 32'b0;
		spare0_io_reg <= 32'b0;
		diagnostic_led_reg <= 32'b0;
	end
	else
	begin
		ver_reg <= {16'b0,FPGA_MAJOR_VER,FPGA_REV};
		rev_data_reg <= {FPGA_REV_YEAR,FPGA_REV_MONTH,FPGA_REV_DAY,FPGA_REV_HOUR};
		dip_sw_reg <= {28'b0,dipsw3,dipsw2,dipsw1,dipsw0};
		buttons_reg[5:0] <= buttons_meta;
		buttons_meta <= {btn3no,btn3nc,btn2no,btn2nc,btn1no,btn1nc};
		drape_sensor_reg[1:0] <= drape_sensor_meta;
		drape_sensor_meta <= {lsw_2,lsw_1};
		spare1_io_reg[16:0] <= spare1_io_meta;
		spare1_io_meta <= spare1_io;
		
		if(data_mosi_rdy)
			case(addr)
				ADDR_FPGA_BUTTONS_LED:
					buttons_led_reg <= data_mosi[31:0];	//{25'b0,data_mosi[6:4],1'b0,data_mosi[2:0]};
				ADDR_FPGA_SPARE0_IO:
					spare0_io_reg <= data_mosi[31:0];
				ADDR_FPGA_SPARE1_IO:
					spare1_io_reg[31:27] <= data_mosi[31:27];
				ADDR_FPGA_BUTTONS:
					buttons_reg[31:6] <= data_mosi[31:6];
				ADDR_FPGA_DRAPE_SWITCH:
					drape_sensor_reg[31:2] <= data_mosi[31:2];
				ADDR_FPGA_DIAG_LEDS:
					diagnostic_led_reg[31:0] <= data_mosi[31:0];	
				default:
					;
			endcase
	end
/*
always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		buttons_led_reg <= 32'b0;
		spare0_io_reg <= 32'b0;
	end
    else if(data_mosi_rdy)
	begin
		case(addr)
			ADDR_FPGA_BUTTONS_LED:
				buttons_led_reg <= {25'b0,data_mosi[6:4],1'b0,data_mosi[2:0]};
			ADDR_FPGA_SPARE0_IO:
				spare0_io_reg <= data_mosi[31:0];
			default:
				;
		endcase
	end
*/

endmodule	

