/////////////////////////////////////////////////////////
//	File			: motor_control.v
//	Author			: Igor Dorman. tracePCB.
//	Date			: 26/10/2022
//	Description		: Motors 1-3 Control.
//	Revision		: 1.0
//	Hierarchy		: top_4mb <- motor_control
//	Last Update		: 30/10/2022 
//////////////////////////////////////////////////////////

module motor_control
#(parameter ADDR_FPGA_INC=0, parameter ADDR_FPGA_INC_ERROR=1, 
parameter ADDR_FPGA_DEF_TICKS=2,parameter ADDR_FPGA_ABSOLUTE=3,
parameter ADDR_FPGA_MOTION_CONTROL=4,parameter ADDR_FPGA_PWM_CYCLE=5, 
parameter ADDR_FPGA_FEEDBACK=6,parameter ADDR_FPGA_DRIVER_CONTROL=7)
(
	//System signals
    clk_100m,       	// system clock
    rst_n_syn,      	// low active synchronous reset
	//clk_1m, 
	//Internal signls
    data_mosi,		// received data from SPI master
    data_mosi_rdy,	// when 1, received data is valid
	addr,			// received data from SPI master
	qca,
	qcb,
	qci,
	ssi_d,
	ssi_c,
	nfault,
	droff,
	pwm,
	brake,
	fgout,
	incr_enc_cnt_reg,
	incr_enc_error_reg,
	incr_enc_def_ticks_reg,
	abs_enc_position_reg,
	motion_control_reg,
	pwm_cycle_reg,
	driver_feedback_reg,
	driver_control_reg
);

`include  "parameters_4mb.v"

input 		clk_100m; 
input 		rst_n_syn; 
//input		clk_1m; 
input[31:0]	data_mosi;
input		data_mosi_rdy;
input[15:0]	addr;
input		qca;
input		qcb;
input		qci;
input		ssi_d;
output		ssi_c;
input		nfault;
output		droff;
output		pwm;
output		brake;
output		fgout;
output[31:0] 	incr_enc_cnt_reg;
output[31:0] 	incr_enc_error_reg;
output[31:0] 	incr_enc_def_ticks_reg;
output[31:0] 	abs_enc_position_reg;
output[31:0] 	motion_control_reg;
output[31:0] 	pwm_cycle_reg;
output[31:0] 	driver_feedback_reg;
output[31:0] 	driver_control_reg;

reg[31:0] 	incr_enc_cnt_reg;
reg[31:0] 	incr_enc_error_reg;
wire[31:0]	incr_enc_error;
reg[31:0] 	incr_enc_def_ticks_reg;
reg[31:0] 	abs_enc_position_reg;
reg[31:0] 	motion_control_reg;
reg[31:0] 	pwm_cycle_reg;
wire[31:0] 	driver_feedback_reg;
reg[31:0] 	driver_control_reg;
reg			nfault_reg;
reg			nfault_meta;
reg[23:0]	fgout_cnt;
reg[23:0]	fgout_cnt_reg;
reg[2:0]	fgout_reg;
wire		brake;
reg[31:0] 	wheel_cnt;
reg[31:0] 	wheel_cnt_last;
reg[2:0] 	quadA_delayed;
reg[2:0]	quadB_delayed;
reg[2:0]	quadI_delayed;
reg[32:0]	qci_cnt;
reg			qci_cnt_en; //IIncremental Index counter starts count only after first index pulse received
reg[4:0]	ssi_clk_cnt;
reg			ssi_clk_posedge;
reg			ssi_clk_negedge;
reg[9:0]	ssi_read_cnt;
reg			ssi_read;
reg[3:0]	ssi_read_quntity;
reg			ssi_c;
reg[27:0]	ssi_data_reg;
reg[4:0]	ssi_bit_cnt;
wire 		cnt_en;
reg 		cnt_dir;
wire 		qci_posedge;
wire		droff;
reg[23:0]	pwm_cnt;
reg			pwm;

assign brake = motion_control_reg[24];
assign driver_feedback_reg = {nfault_reg,7'b0,fgout_cnt_reg};
assign droff = driver_control_reg[0];

always @(posedge clk_100m, negedge rst_n_syn)
	if(!rst_n_syn)
	begin
		nfault_reg <= 0;
		nfault_meta <= 0;
	end
	else
	begin
		nfault_reg <= nfault_meta;
		nfault_meta <= nfault;
	end
	
assign fgout_posedge = ~fgout_reg[2] & fgout_reg[1];
	
always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		fgout_reg <= 1'b0;
		fgout_cnt <= 24'b0;
		fgout_cnt_reg <= 24'b0;
	end
	else
	begin
		fgout_reg <= {fgout_reg[1:0], fgout};
		if(fgout_posedge)
		begin	
			fgout_cnt_reg <= fgout_cnt;
			fgout_cnt <= 24'b0;
		end
		else
		begin
			fgout_cnt <= fgout_cnt + 1;
		end
	end

always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		incr_enc_def_ticks_reg <= DEF_ENCODER_TICKS;//32'h00000FFF;
		motion_control_reg <= 32'b0;
		pwm_cycle_reg <= 32'b0;
		driver_control_reg <= 32'b0;
	end
    else if(data_mosi_rdy)
	begin
		case(addr)
			ADDR_FPGA_DEF_TICKS:
				incr_enc_def_ticks_reg <= data_mosi;
			ADDR_FPGA_MOTION_CONTROL:
				motion_control_reg <= {7'b0,data_mosi[24:0]};
			ADDR_FPGA_PWM_CYCLE:
				pwm_cycle_reg <= {8'b0,data_mosi[23:0]};
			ADDR_FPGA_DRIVER_CONTROL:
				driver_control_reg <= {31'b0,data_mosi[0]};
			default:
				;
		endcase
	end
	

reg	state_pwm;
reg	next_state_pwm;
	
parameter 	PWM_IDLE = 0,
			PWM_ON = 1;
			//PWM_OFF = 2;

always @*
	case(state_pwm)
		PWM_IDLE:
		begin
			if(pwm_cycle_reg[23:0] < MOTOR_PWM_MAX_FREQ)
				next_state_pwm = PWM_IDLE;
			else if(motion_control_reg[23:0] >= pwm_cycle_reg[23:0])
				next_state_pwm = PWM_IDLE;
			else if(pwm_cnt != 0 && pwm_cnt < pwm_cycle_reg[23:0])
				next_state_pwm = PWM_IDLE;
			else if((motion_control_reg[23:0] > 0) && (motion_control_reg[23:0] < pwm_cycle_reg[23:0]))
				next_state_pwm = PWM_ON;
			else
				next_state_pwm = PWM_IDLE;
		end
		PWM_ON:
		begin
			if(pwm_cnt < motion_control_reg[23:0])
				next_state_pwm = PWM_ON;
			else
				next_state_pwm = PWM_IDLE;
		end
		default:
				next_state_pwm = PWM_IDLE;
				
	endcase

			
always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		pwm <= 1'b0;
		pwm_cnt <= 24'b0;
		state_pwm <= 1'b0;
		next_state_pwm <= 1'b0;
	end
	else
	begin
		state_pwm <= next_state_pwm;
		case(state_pwm)
			PWM_IDLE:
			begin
				pwm <= 1'b0;
				pwm_cnt <= 24'b0;
				if(pwm_cnt != 0 && pwm_cnt < pwm_cycle_reg[23:0])
					pwm_cnt <= pwm_cnt + 1'b1;
			end
			PWM_ON:
			begin
				pwm <= 1'b1;
				pwm_cnt <= pwm_cnt + 1'b1;
				if(next_state_pwm == PWM_IDLE)
					pwm <= 1'b0;
			end
			default:
			begin
				pwm <= 1'b0;
				pwm_cnt <= 24'b0;
			end
				
		endcase
	end

//Incremental Encoder	
assign cnt_en = (quadA_delayed[1] & ~quadA_delayed[2]) | (~quadA_delayed[1] & quadA_delayed[2]) 
				| (quadB_delayed[1] & ~quadB_delayed[2]) | (~quadB_delayed[1] & quadB_delayed[2]);

assign qci_posedge = ~quadI_delayed[2] & quadI_delayed[1];
assign incr_enc_error = qci_cnt - incr_enc_def_ticks_reg;

always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		wheel_cnt <= 32'b0;
		qci_cnt <= DEF_ENCODER_TICKS;
		wheel_cnt_last <= 1'b0;
		incr_enc_cnt_reg <= 32'b0;
		incr_enc_error_reg <= 1'b0;
		quadA_delayed <= 1'b0;
		quadB_delayed <= 1'b0;
		quadI_delayed <= 1'b0;
		qci_cnt_en <= 1'b0;
	end	
	else
	begin
		quadA_delayed <= {quadA_delayed[1:0], qca};
		quadB_delayed <= {quadB_delayed[1:0], qcb};
		quadI_delayed <= {quadI_delayed[1:0], qci};
		
		if(quadA_delayed[1] & ~quadA_delayed[2])
			cnt_dir <= !quadB_delayed[2];
		
		if(cnt_en)
		begin
			if(qci_cnt_en)
				qci_cnt <= qci_cnt + 1;
				
			if(cnt_dir)
			begin
				if(wheel_cnt[31:0] == 31'h7FFFFFFF)
					wheel_cnt <= 32'h00000000;
				else
					wheel_cnt <= wheel_cnt + 1;
			end					
			else
			begin			
				if(wheel_cnt[31:0] == 31'h80000000)
					wheel_cnt <= 32'hFFFFFFFF;
				else
					wheel_cnt <= wheel_cnt - 1;
			end
		end
		
		if(wheel_cnt_last != wheel_cnt)
		begin
			wheel_cnt_last <= wheel_cnt;
			incr_enc_cnt_reg <= wheel_cnt;
		end
		
		if(data_mosi_rdy && addr == ADDR_FPGA_INC_ERROR)
			incr_enc_error_reg <= 32'b0;
			
		if(qci_posedge)
		begin
			qci_cnt_en <= 1'b1;
			qci_cnt <=	14'b0;
			
			if(incr_enc_error[31])
			begin
				if((incr_enc_error_reg == 0) || (incr_enc_error_reg > incr_enc_error))
					incr_enc_error_reg <= incr_enc_error;
			end
			else
			begin
				if(incr_enc_error_reg < incr_enc_error)
					incr_enc_error_reg <= incr_enc_error;
			end
		end
	end

	
//Absolute Encoder(SSI)
always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		ssi_read_cnt <= 5'b0;
		ssi_read <= 1'b0;
	end
	else
	begin
		ssi_read <= 1'b0;
		ssi_read_cnt <= ssi_read_cnt + 1'b1;
		if(ssi_read_cnt == XMARS_READ_PERIOD)
		begin
			ssi_read_cnt <= 5'b0;
			ssi_read <= 1'b1;
		end
	end

always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		ssi_clk_cnt <= 5'b0;
		ssi_clk_posedge <= 1'b0;
		ssi_clk_negedge <= 1'b0;
	end
	else
	begin
		ssi_clk_cnt <= ssi_clk_cnt + 1'b1;
		ssi_clk_posedge <= 1'b0;
		ssi_clk_negedge <= 1'b0;
		
		if(ssi_clk_cnt == XMARS_CLOCK_PERIOD)
		begin
			ssi_clk_cnt <= 5'b0;
			ssi_clk_posedge <= 1'b1;
			ssi_clk_cnt <= 5'b0;
		end
		else if(ssi_clk_cnt == (XMARS_CLOCK_PERIOD/2))
		begin	
			ssi_clk_negedge <= 1'b1;
		end
	end
		

reg[1:0]	state_ssi;
parameter
	SSI_IDLE		= 0,
	SSI_START		= 1,
    SSI_FALL_EDGE	= 2,
    SSI_RISE_EDGE	= 3;
	
always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		ssi_bit_cnt <= 5'b0;
		ssi_c <= 1'b1;
		ssi_data_reg <= 28'b0;
		ssi_read_quntity <= 4'b0;
		abs_enc_position_reg <= 32'b0;
		state_ssi <= SSI_IDLE;
	end
	else
	begin
		case(state_ssi)
			SSI_IDLE:
			begin
				ssi_bit_cnt <= 5'b0;
				ssi_c <= 1'b1;
				ssi_data_reg <= 28'b0;
				if(ssi_read)
				begin
					state_ssi <= SSI_START;
					ssi_read_quntity <= ssi_read_quntity + 1;
				end
				else
				begin
					state_ssi <= SSI_IDLE;
				end
			end
			SSI_START:
			begin
				ssi_bit_cnt <= 5'b0;
				ssi_c <= 1'b1;
				if(ssi_clk_negedge)
				begin
					state_ssi <= SSI_FALL_EDGE;
					ssi_c <= 1'b0;
				end
				else
				begin
					state_ssi <= SSI_START;
				end
			end	
			SSI_FALL_EDGE:
			begin
				if(ssi_clk_posedge)
				begin
					ssi_c <= 1'b1;
					if(ssi_bit_cnt < XMARS_DATA_BITS)
					begin
						ssi_bit_cnt <= ssi_bit_cnt + 1'b1;
						state_ssi <= SSI_RISE_EDGE;
					end
					else
					begin
						ssi_bit_cnt <= 5'b0;
						abs_enc_position_reg[27:0] <= ssi_data_reg;
						abs_enc_position_reg[31:28] <= ssi_read_quntity;						
						state_ssi <= SSI_IDLE;
					end
				end
				else
				begin
					state_ssi <= SSI_FALL_EDGE;
				end
			end				
			SSI_RISE_EDGE:
			begin
				if(ssi_clk_negedge)
				begin
					ssi_c <= 1'b0;
					ssi_data_reg[27:0] <= {ssi_data_reg[26:0],ssi_d};
					state_ssi <= SSI_FALL_EDGE;
				end
				else
				begin
					state_ssi <= SSI_RISE_EDGE;
				end
			end
		endcase
	end


endmodule	

