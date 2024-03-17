/////////////////////////////////////////////////////////
//	File			: rcb_test_de10.v
//	Author			: Igor Dorman. tracePCB.
//	Date			: 19/10/2022
//	Description		: RCB Registers.
//	Revision		: 1.0
//	Hierarchy		: rcb_test_de10
//	Last Update		: 19/10/2022 
//////////////////////////////////////////////////////////

module rcb_test_de10(
	//System signals
    clk_100m,       	// system clock
    rst_n,      		// low active synchronous reset
	clk_1m, 
	led_r8,
	led_r9

);
	
//`include  "rcb_parameters.v"	
	
input 			clk_100m; 
input 			rst_n; 
input			clk_1m; 

output 			led_r8; 
output			led_r9;

reg[31:0]		cnt_100m;
reg[31:0]		cnt_100k;

reg 			led_r8; 
reg				led_r9;

always @(posedge clk_100m, negedge rst_n)
	if(!rst_n)
	begin
		cnt_100m <= 32'b0;
		led_r8 <= 1'b0;
	end
	else
	begin
		if(cnt_100m == 32'h00FFFFFF)//h05F5E100)
		begin
			cnt_100m <= 32'b0;
			led_r8 <= !led_r8;
		end
		else	
			cnt_100m <= cnt_100m + 1;
	end
	

always @(posedge clk_1m, negedge rst_n)
	if(!rst_n)
	begin
		cnt_100k <= 32'b0;
		led_r9 <= 1'b0;
	end
	else
	begin
		if(cnt_100k == 32'h00028F5C)
		begin
			cnt_100k <= 32'b0;
			led_r9 <= !led_r9;
		end
		else	
			cnt_100k <= cnt_100k + 1;
	end


endmodule	

