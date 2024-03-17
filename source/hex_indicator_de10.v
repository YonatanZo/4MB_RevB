/////////////////////////////////////////////////////////
//	File			: hex_indicator_de10.v
//	Author			: Igor Dorman. tracePCB.
//	Date			: 29/12/2022
//	Description		: 
//	Revision		: 1.0
//	Hierarchy		: hex_indicator_de10
//	Last Update		: 29/12/2022 
//////////////////////////////////////////////////////////

module hex_indicator_de10(
	in_reg1,
	in_reg2,
	hex0,
	hex1,
	hex2,
	hex3,
	hex4,
	hex5
);
	

	
input[31:0] 	in_reg1;
input[31:0] 	in_reg2;  
output[7:0]		hex0; 
output[7:0]		hex1;
output[7:0]		hex2;
output[7:0]		hex3;
output[7:0]		hex4;
output[7:0]		hex5;

reg[7:0]		hex0; 
reg[7:0]		hex1;
reg[7:0]		hex2;
reg[7:0]		hex3;
reg[7:0]		hex4;
reg[7:0]		hex5;
reg[7:0]  		hex_reg;    
integer         i;
reg [3:0]  		ones;
reg [3:0]  		tens;

`include  "parameters_4mb.v"	


always @*
begin
    case(FPGA_MAJOR_VER)
		0:
			hex1 = 8'b01000000;
		1:
			hex1 = 8'b01111001;
		2:
			hex1 = 8'b00100100;
		3:
			hex1 = 8'b00110000;
		4:
			hex1 = 8'b00011001;
		5:
			hex1 = 8'b00010010;
		6:
			hex1 = 8'b00000010;
		7:
			hex1 = 8'b01111000;
		8:
			hex1 = 8'b00000000;
		9:
			hex1 = 8'b00010000;
		default:
			hex1 = 8'b01111111;
	endcase
	
	//hex4 = ~in_reg[3:0];//8'hFF;
	//hex5 = IEF3_DEF_TICKS;//IEF3_DEF_TICKS;//~in_reg[7:4];//8'hFF;
end

always @*
begin
    case(FPGA_REV)
		0:
			hex0 = 8'b11000000;
		1:
			hex0 = 8'b11111001;
		2:
			hex0 = 8'b10100100;
		3:
			hex0 = 8'b10110000;
		4:
			hex0 = 8'b10011001;
		5:
			hex0 = 8'b10010010;
		6:
			hex0 = 8'b10000010;
		7:
			hex0 = 8'b11111000;
		8:
			hex0 = 8'b10000000;
		9:
			hex0 = 8'b10010000;
		default:
			hex0 = 8'b01111111;
	endcase
end

always @*
begin
    case(ones)
		0:
			hex2 = 8'b11000000;
		1:
			hex2 = 8'b11111001;
		2:
			hex2 = 8'b10100100;
		3:
			hex2 = 8'b10110000;
		4:
			hex2 = 8'b10011001;
		5:
			hex2 = 8'b10010010;
		6:
			hex2 = 8'b10000010;
		7:
			hex2 = 8'b11111000;
		8:
			hex2 = 8'b10000000;
		9:
			hex2 = 8'b10010000;
		default:
			hex2 = 8'b01111111;
	endcase
end

always @*
begin
    case(tens)
		0:
			hex3 = 8'b11000000;
		1:
			hex3 = 8'b11111001;
		2:
			hex3 = 8'b10100100;
		3:
			hex3 = 8'b10110000;
		4:
			hex3 = 8'b10011001;
		5:
			hex3 = 8'b10010010;
		6:
			hex3 = 8'b10000010;
		7:
			hex3 = 8'b11111000;
		8:
			hex3 = 8'b10000000;
		9:
			hex3 = 8'b10010000;
		default:
			hex3 = 8'b01111111;
	endcase
end

always @ (*)
begin
    hex_reg = in_reg1[7:0];
    ones = 0;
    tens = 0;
     
    for (i = 7; i >= 0; i = i-1) 
	begin
        if(tens >= 5)
            tens = tens + 3;        
        if(ones >= 5)
            ones = ones + 3;        

        tens = tens << 1;
        tens[0]= ones[3];
        ones = ones << 1;
        ones[0] = hex_reg[7];
        hex_reg = {hex_reg[6:0], 1'b0};
    end
end


always @*
begin
    case(in_reg2[3:0])
		0:
			hex4 = 8'b11000000;
		1:
			hex4 = 8'b11111001;
		2:
			hex4 = 8'b10100100;
		3:
			hex4 = 8'b10110000;
		4:
			hex4 = 8'b10011001;
		5:
			hex4 = 8'b10010010;
		6:
			hex4 = 8'b10000010;
		7:
			hex4 = 8'b11111000;
		8:
			hex4 = 8'b10000000;
		9:
			hex4 = 8'b10010000;
		default:
			hex4 = 8'b01111111;
	endcase
end

always @*
begin
    case(in_reg2[7:4])
		0:
			hex5 = 8'b11000000;
		1:
			hex5 = 8'b11111001;
		2:
			hex5 = 8'b10100100;
		3:
			hex5 = 8'b10110000;
		4:
			hex5 = 8'b10011001;
		5:
			hex5 = 8'b10010010;
		6:
			hex5 = 8'b10000010;
		7:
			hex5 = 8'b11111000;
		8:
			hex5 = 8'b10000000;
		9:
			hex5 = 8'b10010000;
		default:
			hex5 = 8'b01111111;
	endcase
end

/*
reg     [15:0]  hex_reg;    
integer         i;
always @ (*)
begin
    hex_reg = hex;
    ones = 0;
    tens = 0;
    hundreds = 0;
    thousands = 0;
    ten_thousands = 0;
     
    for (i = 15; i >= 0; i = i-1) begin
        if(ten_thousands >= 5)
        ten_thousands = ten_thousands + 3;
        if(thousands >= 5)
            thousands = thousands + 3;
        if(hundreds >= 5)
            hundreds = hundreds + 3;
        if(tens >= 5)
            tens = tens + 3;        
        if(ones >= 5)
            ones = ones + 3;        
 
        ten_thousands = ten_thousands << 1; 
        ten_thousands[0] = thousands[3];    
        thousands = thousands << 1;
        thousands[0] = hundreds[3];     
        hundreds = hundreds << 1;
        hundreds[0] = tens[3];
        tens = tens << 1;
        tens[0]= ones[3];
        ones = ones << 1;
        ones[0] = hex_reg[15];
        hex_reg = {hex_reg[14:0], 1'b0};
    end
end
*/


endmodule	

