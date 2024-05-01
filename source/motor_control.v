/////////////////////////////////////////////////////////
//	File			: motor_control.v
//	Author			: Igor Dorman. tracePCB.
//	Date			: 26/10/2022
//	Description		: Motors 1-3 Control.
//	Revision		: 1.0
//	Hierarchy		: top_4mb <- motor_control
//	Last Update		: 05/03/2023 
//////////////////////////////////////////////////////////

module motor_control
#(parameter ADDR_FPGA_INC=0, parameter ADDR_FPGA_INC_ERROR=1, 
parameter ADDR_FPGA_DEF_TICKS=2,parameter ADDR_FPGA_ABSOLUTE=3,
parameter ADDR_FPGA_MOTION_CONTROL=4,parameter ADDR_FPGA_PWM_CYCLE=5, 
parameter ADDR_FPGA_FEEDBACK=6,parameter ADDR_FPGA_DRIVER_CONTROL=7,
parameter DEF_ENCODER_TICKS=4096,parameter ENCODER_DATA_BITS=44,
parameter ENCODER_CLOCK_PERIOD=26,parameter ENCODER_READ_PERIOD=1000
)
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
	driver_control_reg,
	ssi_read_quntity,
	mosi_status,
	crc_err_cnt,
	status_bits
);

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
input		fgout;
output[31:0] 	incr_enc_cnt_reg;
output[31:0] 	incr_enc_error_reg;
output[31:0] 	incr_enc_def_ticks_reg;
output[31:0] 	abs_enc_position_reg;
output[31:0] 	motion_control_reg;
output[31:0] 	pwm_cycle_reg;
output[31:0] 	driver_feedback_reg;
output[31:0] 	driver_control_reg;
output[3:0]		ssi_read_quntity;
input[1:0]		mosi_status;
output[7:0]		crc_err_cnt;
output[1:0]		status_bits;

`include  "parameters_4mb.v"

reg[31:0] 	incr_enc_cnt_reg;
reg[31:0] 	incr_enc_error_reg;
wire[31:0]	incr_enc_error;
reg[31:0] 	incr_enc_def_ticks_reg;
reg[31:0] 	abs_enc_position_reg;
//reg[7:0] 	abs_enc_staus_reg;
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

reg[31:0]	qci_cnt;
reg			qci_cnt_en; //Incremental Index counter starts count only after first index pulse received
reg 		inc_enc_cnt_en;
reg 		inc_enc_cnt_dir;
reg 		qci_cnt_rst;
reg[7:0]	ssi_clk_cnt;
reg			ssi_clk_posedge;
reg			ssi_clk_negedge;
reg[13:0]	ssi_read_cnt;
reg			ssi_read;
reg[3:0]	ssi_read_quntity;
reg			ssi_c;
reg[ENCODER_DATA_BITS-1:0]	ssi_data_reg;
reg[5:0]	ssi_bit_cnt;
reg[5:0]	crc_calc;
wire		droff;
reg[23:0]	pwm_cnt;
reg			pwm;
wire		fgout_posedge;
//reg[5:0]	newcrc;
reg[7:0]	crc_err_cnt;
reg[1:0]	status_bits;

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
		nfault_meta <= nfault;
		nfault_reg <= nfault_meta;
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
			fgout_cnt <= fgout_cnt + 1'b1;
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
				motion_control_reg <= data_mosi[31:0]; //{7'b0,data_mosi[24:0]};
			ADDR_FPGA_PWM_CYCLE:
				pwm_cycle_reg <= data_mosi[31:0];	//{8'b0,data_mosi[23:0]};
			ADDR_FPGA_DRIVER_CONTROL:
				driver_control_reg <= data_mosi[31:0];	//{31'b0,data_mosi[0]};
			/*ADDR_FPGA_INC_ERROR:
				incr_enc_error_reg <= 32'b0;*/
			default:
				;
		endcase
	end
	

reg	state_pwm;
	
parameter 	PWM_IDLE = 1'b0,
			PWM_ON = 1'b1;
			
always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		state_pwm <= 1'b0;
		pwm <= 1'b0;
		pwm_cnt <= 24'b0;
	end
	else
	begin
		case(state_pwm)
			PWM_IDLE:
			begin
				pwm <=1'b0;
				pwm_cnt <= 24'b0;
				if(pwm_cycle_reg[23:0] < MOTOR_PWM_MAX_FREQ)
				begin
					state_pwm <= PWM_IDLE;
				end
				else if(motion_control_reg[23:0] >= pwm_cycle_reg[23:0])
				begin	
					state_pwm <= PWM_IDLE;
					pwm <= 1'b1;
				end
				else if(pwm_cnt != 0 && pwm_cnt < pwm_cycle_reg[23:0])
				begin
					pwm_cnt <= pwm_cnt + 1'b1;
				end
				else if((motion_control_reg[23:0] > 0) && (motion_control_reg[23:0] < pwm_cycle_reg[23:0]))
				begin
					state_pwm <= PWM_ON;
				end
				else
				begin
					state_pwm <= PWM_IDLE;
				end
			end
			PWM_ON:
			begin
				pwm <= 1'b1;
				pwm_cnt <= pwm_cnt + 1'b1;
				if(pwm_cnt < motion_control_reg[23:0])
				begin
					state_pwm <= PWM_ON;
				end
				else
				begin
					state_pwm <= PWM_IDLE;
					pwm <= 1'b0;
				end
			end
			default:
				state_pwm <= PWM_IDLE;
		endcase
	end


//Incremental Encoder	
//Incremental Encoder Debouncer
reg[4:0] qca_deb_cnt;
reg qca_deb;
reg[4:0] qcb_deb_cnt;
reg qcb_deb;
reg[4:0] qci_deb_cnt;
reg qci_deb;
	
always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		qca_deb_cnt <= 0;
		qca_deb <= 0;
		qcb_deb_cnt <= 0;
		qcb_deb <= 0;
		qci_deb_cnt <= 0;
		qci_deb <= 0;
	end
	else
	begin
		qca_deb_cnt[4:0] <= {qca_deb_cnt[3:0],qca};
		qca_deb <= &qca_deb_cnt;
		qcb_deb_cnt[4:0] <= {qcb_deb_cnt[3:0],qcb};
		qcb_deb <= &qcb_deb_cnt;
		qci_deb_cnt[4:0] <= {qci_deb_cnt[3:0],qci};
		qci_deb <= &qci_deb_cnt;	
	end
	
reg qca_del;
reg	qcb_del;
reg	qci_del;

//assign qci_cnt_rst = ~qcb_del & qci_deb;
assign incr_enc_error = qci_cnt - (incr_enc_def_ticks_reg - 1'b1);

always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		qci_cnt <= DEF_ENCODER_TICKS - 1'b1;
		incr_enc_cnt_reg <= 'b0;
		incr_enc_error_reg <= 1'b0;
		qca_del <= 1'b0;
		qcb_del <= 1'b0;
		qci_del <= 1'b0; //was qci_del
		qci_cnt_en <= 1'b0;
		qci_cnt_rst <= 1'b0;
		inc_enc_cnt_dir <= 1'b0;
	end	
	else
	begin
		qca_del <= qca_deb;
		qcb_del <= qcb_deb;
		qci_del <= qci_deb;
				
		if(qca_deb && !qca_del)	//QCA Rising edge
		begin
			inc_enc_cnt_en <= 1'b1;
			inc_enc_cnt_dir <= ~qcb_del;
		end
		else if(!qca_deb && qca_del)	//QCA Falling edge
		begin
			inc_enc_cnt_en <= 1'b1;
			inc_enc_cnt_dir <= qcb_del;
		end
		else if(qcb_deb && !qcb_del)	//QCB Rising edge
		begin
			inc_enc_cnt_en <= 1'b1;
			inc_enc_cnt_dir <= qca_del;
		end
		else if(!qcb_deb && qcb_del) //QCB Falling edge
		begin
			inc_enc_cnt_en <= 1'b1;
			inc_enc_cnt_dir <= ~qca_del;
		end
		else
		begin
			inc_enc_cnt_en <= 1'b0;
			//inc_enc_cnt_dir <= inc_enc_cnt_dir;
		end
		
		if(inc_enc_cnt_en)
		begin
			if(qci_cnt_en)	//the index counter is enabled only after the first index is received
			begin
				if(inc_enc_cnt_dir)
				    qci_cnt <= qci_cnt + 1'b1;
				else
					qci_cnt <= qci_cnt - 1'b1;
			end
				
			if(inc_enc_cnt_dir)
			begin
				if(incr_enc_cnt_reg[31:0] == 32'h7FFFFFFF)
					incr_enc_cnt_reg <= 32'h00000000;
				else
					incr_enc_cnt_reg <= incr_enc_cnt_reg + 1'b1;
			end					
			else
			begin			
				if(incr_enc_cnt_reg[31:0] == 32'h80000000)
					incr_enc_cnt_reg <= 32'hFFFFFFFF;
				else
					incr_enc_cnt_reg <= incr_enc_cnt_reg - 1'b1;
			end
		end
		
		qci_cnt_rst <= qci_deb & ~qci_del;
		
		if(qci_cnt_rst)
		begin
			qci_cnt_en <= 1'b1;
			qci_cnt <=	32'b0;
			
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
		
		if(data_mosi_rdy && addr == ADDR_FPGA_INC_ERROR)
			incr_enc_error_reg <= data_mosi[31:0];	//32'b0;
	end

	
//Absolute Encoder(SSI)
always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		ssi_read_cnt <= 'b0;
		ssi_read <= 1'b0;
	end
	else
	begin
		ssi_read <= 1'b0;
		ssi_read_cnt <= ssi_read_cnt + 1'b1;
		if(ssi_read_cnt == ENCODER_READ_PERIOD)
		begin
			ssi_read_cnt <= 'b0;
			ssi_read <= 1'b1;
		end
	end

always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		ssi_clk_cnt <= 8'b0;
		ssi_clk_posedge <= 1'b0;
		ssi_clk_negedge <= 1'b0;
	end
	else
	begin
		ssi_clk_cnt <= ssi_clk_cnt + 1'b1;
		ssi_clk_posedge <= 1'b0;
		ssi_clk_negedge <= 1'b0;
		
		if(ssi_clk_cnt == ENCODER_CLOCK_PERIOD)
		begin
			ssi_clk_cnt <= 8'b0;
			ssi_clk_posedge <= 1'b1;
		end
		else if(ssi_clk_cnt == (ENCODER_CLOCK_PERIOD/2))
		begin	
			ssi_clk_negedge <= 1'b1;
		end
	end
	
// SSI Communication State Machine
reg[1:0]	state_ssi;
parameter
	SSI_IDLE		= 0,
	SSI_START		= 1,
    SSI_FALL_EDGE	= 2,
    SSI_RISE_EDGE	= 3;
	
always @(posedge clk_100m, negedge rst_n_syn)
    if(!rst_n_syn)
	begin
		ssi_bit_cnt <= 6'b0;
		ssi_c <= 1'b1;
		ssi_data_reg <= 'b0;
		ssi_read_quntity <= 4'b0;
		abs_enc_position_reg <= 32'b0;
		state_ssi <= SSI_IDLE;
		crc_err_cnt <= 'b0;
		status_bits <= 'b0;
		crc_calc <= 0;
		//newcrc <= 0;
		
	end
	else
	begin
		if(data_mosi_rdy && ADDR_FPGA_M1_3_ABS_ENC_STATUS)
		begin
			status_bits <= mosi_status;
		end
		
		case(state_ssi)
			SSI_IDLE:
			begin
				ssi_bit_cnt <= 6'b0;
				ssi_c <= 1'b1; // Keep SSI clock high when idle
				ssi_data_reg <= 'b0;
				if(ssi_read)
				begin
					state_ssi <= SSI_START;
					ssi_read_quntity <= ssi_read_quntity + 1'b1; // Increment read count
				end
				else
				begin
					state_ssi <= SSI_IDLE;
				end
			end
			SSI_START:
			begin
				ssi_bit_cnt <= 6'b0;
				ssi_c <= 1'b1;
				crc_calc <= 0; // Reset CRC calculation
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
					if(ssi_bit_cnt < ENCODER_DATA_BITS)
					begin
						ssi_bit_cnt <= ssi_bit_cnt + 1'b1;
						state_ssi <= SSI_RISE_EDGE;
					end
					else
					begin
						ssi_bit_cnt <= 6'b0;
						abs_enc_position_reg[31:0] <= ssi_data_reg[ENCODER_DATA_BITS-5:ENCODER_DATA_BITS-36];//[39:8]// Update absolute position
						
						//if((/*newcrc*/nextCRCx43_D1(ssi_data_reg[8],ssi_data_reg[5:0]) != ssi_data_reg[5:0]))// && (abs_enc_staus_reg[31:16] != 16'hFFFF))	//CRC counter.
						if(crc_calc)
							crc_err_cnt <= crc_err_cnt + 1'b1;
							
						if(ssi_data_reg[7])			//Error Status bit
							status_bits[1] <= 1'b1;
						
						if(ssi_data_reg[6])			//Warning Status bit
							status_bits[0] <= 1'b1;
							
						//abs_enc_staus_reg[7:0] <= ssi_data_reg[7:0];
						//abs_enc_position_reg[27:24] <= 'b0;
						//abs_enc_position_reg[31:28] <= ssi_read_quntity;						
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
					ssi_data_reg[ENCODER_DATA_BITS-1:0] <= {ssi_data_reg[ENCODER_DATA_BITS-2:0],ssi_d};
					
					if(ssi_bit_cnt > 4)
					begin
						if(ssi_bit_cnt < 39)
							crc_calc = nextCRCx43_D0(ssi_d,crc_calc);
						else
							crc_calc = nextCRCx43_D0(!ssi_d,crc_calc);
					end
						
					state_ssi <= SSI_FALL_EDGE;
				end
				else
				begin
					state_ssi <= SSI_RISE_EDGE;
				end
			end
		endcase
	end

	
// CRC calculation logic implemented as a function for reusability
function reg[5:0] nextCRCx43_D0;
	input		data;
	input[5:0]	crc;
	reg[5:0]	newcrc;
	begin
		newcrc[0] = crc[5] ^ data;
		newcrc[1] = crc[0] ^ data ^ crc[5];
		newcrc[2] = crc[1];
		newcrc[3] = crc[2];
		newcrc[4] = crc[3];
		newcrc[5] = crc[4];
		nextCRCx43_D0 = newcrc;
	end
endfunction

endmodule	

