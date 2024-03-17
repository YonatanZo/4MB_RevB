/////////////////////////////////////////////////
//	File			: pwm_de10.v
//	Author			: Igor Dorman. tracePCB.
//	Date			: 16/01/2023
//	Description		: 
//	Revision		: 1.0
//	Hierarchy		: pwm_de10
//	Last Update		: 18/01/2023 
/////////////////////////////////////////////////

module pwm_de10(
	clk_100m,
	rst_n,
	key0,
	key1,
	sw0,
	pwm,
	hex0,
	hex1,
	hex2,
	hex3,
	hex4,
	hex5
);

//`include  "parameters_4mb.v"
parameter	SYS_CLOCK = 100000000;// Sys_Clock(100MHz)
parameter	PWM_FREQ = 1000;	// 1kHz
parameter	PACKET_FREQ = 60;	// 60Hz
parameter	NUM_SAMPLES = 100;	// Number of samples 
parameter	SAMPLE_FREQ = SYS_CLOCK/(PWM_FREQ * NUM_SAMPLES);	//100kHz
parameter	PACKET_SAMPLE = SYS_CLOCK/(60 * SAMPLE_FREQ);	//Number of samples in the Period of packets (60Hz)
parameter	PWM_STEPS = NUM_SAMPLES-1;//100;	//Quantity of steps of PWM duty cycle
parameter	PACKET_STEPS = PACKET_SAMPLE;//1666;	//Quantity of steps of PACKET duty cycle
parameter	KEY_DEBOUNCE_DEEP = 10;//100;
	

input			clk_100m;
input			rst_n;	
input		 	key0;
input			key1;
input			sw0; 
output			pwm; 
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
reg[7:0]  		pwm_hex_reg; 
reg[7:0]  		packet_hex_reg;     
integer         i;
reg [7:0]  		pwm_cycle_reg;
reg [16:0]  	pwm_in_cnt;
reg [7:0]  		pwm_cnt;
reg[KEY_DEBOUNCE_DEEP:0]	key0_deb_cnt;
reg[KEY_DEBOUNCE_DEEP:0]	key1_deb_cnt;
reg	key0_reg;
reg key1_reg;
reg	key0_deb;
reg key1_deb;
reg [3:0]  		pwm_ones;
reg [3:0]  		pwm_tens;
reg [3:0]  		packet_ones;
reg [3:0]  		packet_tens;
reg pwm;
wire key0_negedge;
wire key1_negedge;
reg[10:0]	packet_cnt;
reg[10:0]	packet_cycle_reg;

assign key0_negedge = ~key0_reg & ~key0_deb;
assign key1_negedge = ~key1_reg & ~key1_deb;

always @(posedge clk_100m, negedge rst_n)
    if(!rst_n)
	begin
		pwm_cycle_reg <= 'b0;
		packet_cycle_reg <= 833;//'b0;
		key0_deb_cnt <= 'b0;
		key0_deb <= 0;
		key0_reg <= 1;
		key1_deb_cnt <= 'b0;
		key1_deb <= 0;
		key1_reg <= 1;
	end
	else
	begin
		key0_deb_cnt[KEY_DEBOUNCE_DEEP:0] <= {key0_deb_cnt[KEY_DEBOUNCE_DEEP-1:0],key0};
		key0_deb <= &key0_deb_cnt;
		key1_deb_cnt[KEY_DEBOUNCE_DEEP:0] <= {key1_deb_cnt[KEY_DEBOUNCE_DEEP-1:0],key1};
		key1_deb <= &key1_deb_cnt;	
		
		key0_reg <= ~key0_deb;
		key1_reg <= ~key1_deb;
		
		if(key0_negedge)
		begin
			if(!sw0)
			begin
				if(pwm_cycle_reg < PWM_STEPS-5)
					pwm_cycle_reg <= pwm_cycle_reg + 5;//1'b1;
				else	
					pwm_cycle_reg <= PWM_STEPS;
			end
			else
			begin
				if(packet_cycle_reg < PACKET_STEPS-55)
					packet_cycle_reg <= packet_cycle_reg + 55;//1'b1;
				else	
					packet_cycle_reg <= PACKET_STEPS;
			end
		end
		else if(key1_negedge)
		begin
			if(!sw0)
			begin
				if(pwm_cycle_reg > 5)
					pwm_cycle_reg <= pwm_cycle_reg - 5;//1'b1;
				else	
					pwm_cycle_reg <= 0;
			end
			else
			begin
				if(packet_cycle_reg > 55)
					packet_cycle_reg <= packet_cycle_reg - 55;//1'b1;
				else	
					packet_cycle_reg <= 0;
			end			
		end
		else
		begin
			pwm_cycle_reg <= pwm_cycle_reg;
			packet_cycle_reg <= packet_cycle_reg;
		end
	end
	


	
reg[1:0]	state_pwm;	
parameter 	PWM_IDLE = 0,//2'b00,
			PWM_LOW = 1,//2'b01,
			PWM_HIGH = 2;//2'b10;
			
always @(posedge clk_100m, negedge rst_n)
    if(!rst_n)
	begin
		state_pwm <= PWM_IDLE;//1'b0;
		pwm <= 1'b0;
		pwm_cnt <= 'b0;
		pwm_in_cnt <= 'b0;
		packet_cnt <= 0;
	end
	else
	begin
		if(pwm_in_cnt == SAMPLE_FREQ)
		begin
			packet_cnt <= packet_cnt + 1'b1;
			pwm_in_cnt <= 0;
			case(state_pwm)
				PWM_IDLE:
				begin
					pwm_cnt <= 0;
					pwm <= 0;
					if(packet_cycle_reg == 0)
						state_pwm <= PWM_IDLE;
					else if(packet_cnt < (PACKET_SAMPLE - packet_cycle_reg))
						state_pwm <= PWM_IDLE;
					else if(packet_cnt == (PACKET_SAMPLE - packet_cycle_reg))
					begin
						state_pwm <= PWM_LOW;
					end
					else 
						state_pwm <= PWM_IDLE;
				end
				PWM_LOW:
				begin
					pwm <=1'b0;
					pwm_cnt <= pwm_cnt + 1'b1;
					if(pwm_cycle_reg == 0)
					begin
						state_pwm <= PWM_IDLE;
						pwm_cnt <= 0;
						packet_cnt <= 0;
					end
					else if(packet_cnt == PACKET_SAMPLE)
					begin
						state_pwm <= PWM_IDLE;
						pwm_cnt <= 0;
						packet_cnt <= 0;
						pwm <= 0;
					end
					else if(pwm_cnt < (PWM_STEPS - pwm_cycle_reg))
					begin	
						state_pwm <= PWM_LOW;
						
					end
					else if(pwm_cnt == (PWM_STEPS - pwm_cycle_reg))
					begin
						state_pwm <= PWM_HIGH;
						pwm <= 1'b1;
					end
					else
					begin
						state_pwm <= PWM_IDLE;
						pwm_cnt <= 0;
						packet_cnt <= 0;
					end
				end
				PWM_HIGH:
				begin
					pwm <= 1'b1;
					pwm_cnt <= pwm_cnt + 1'b1;
					if(packet_cnt == PACKET_SAMPLE)
					begin
						state_pwm <= PWM_IDLE;
						pwm_cnt <= 0;
						packet_cnt <= 0;
						pwm <= 0;
					end
					else if(pwm_cnt < PWM_STEPS)
					begin
						state_pwm <= PWM_HIGH;
					end
					else
					begin
						state_pwm <= PWM_LOW;
						pwm_cnt <= 0;
					end
				end
				default:
				begin
					state_pwm <= PWM_IDLE;
					packet_cnt <= 0;
					pwm <= 0;
				end
			endcase
		end
		else
		begin
			pwm_in_cnt <= pwm_in_cnt + 1'b1;
		end
	end


always @*
begin
    case(pwm_ones)
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
    case(pwm_tens)
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
    pwm_hex_reg = pwm_cycle_reg;
    pwm_ones = 0;
    pwm_tens = 0;
     
    for (i = 7; i >= 0; i = i-1) 
	begin
        if(pwm_tens >= 5)
            pwm_tens = pwm_tens + 3;        
        if(pwm_ones >= 5)
            pwm_ones = pwm_ones + 3;        

        pwm_tens = pwm_tens << 1;
        pwm_tens[0]= pwm_ones[3];
        pwm_ones = pwm_ones << 1;
        pwm_ones[0] = pwm_hex_reg[7];
        pwm_hex_reg = {pwm_hex_reg[6:0], 1'b0};
    end
end

always @*
begin
    case(packet_ones)
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
    case(packet_tens)
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

always @ (*)
begin
    packet_hex_reg = packet_cycle_reg/17;
    packet_ones = 0;
    packet_tens = 0;
     
    for (i = 7; i >= 0; i = i-1) 
	begin
        if(packet_tens >= 5)
            packet_tens = packet_tens + 3;        
        if(packet_ones >= 5)
            packet_ones = packet_ones + 3;        

        packet_tens = packet_tens << 1;
        packet_tens[0]= packet_ones[3];
        packet_ones = packet_ones << 1;
        packet_ones[0] = packet_hex_reg[7];
        packet_hex_reg = {packet_hex_reg[6:0], 1'b0};
    end
end


/*
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
*/

/*
reg     [15:0]  pwm_hex_reg;    
integer         i;
always @ (*)
begin
    pwm_hex_reg = hex;
    pwm_ones = 0;
    pwm_tens = 0;
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
        if(pwm_tens >= 5)
            pwm_tens = pwm_tens + 3;        
        if(pwm_ones >= 5)
            pwm_ones = pwm_ones + 3;        
 
        ten_thousands = ten_thousands << 1; 
        ten_thousands[0] = thousands[3];    
        thousands = thousands << 1;
        thousands[0] = hundreds[3];     
        hundreds = hundreds << 1;
        hundreds[0] = pwm_tens[3];
        pwm_tens = pwm_tens << 1;
        pwm_tens[0]= pwm_ones[3];
        pwm_ones = pwm_ones << 1;
        pwm_ones[0] = pwm_hex_reg[15];
        pwm_hex_reg = {pwm_hex_reg[14:0], 1'b0};
    end
end
*/


endmodule	

