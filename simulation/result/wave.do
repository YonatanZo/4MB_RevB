onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/dut/clk_100m
add wave -noupdate /tb/dut/rst_n
add wave -noupdate /tb/dut/mclk_0
add wave -noupdate /tb/dut/mosi_0
add wave -noupdate /tb/dut/miso_0
add wave -noupdate /tb/dut/spi_4mb/state
add wave -noupdate /tb/dut/spi_4mb/next_state
add wave -noupdate /tb/dut/cs_00
add wave -noupdate /tb/tb_tester/mosi_data
add wave -noupdate /tb/tb_tester/miso_data
add wave -noupdate /tb/dut/motor4_control/abs_enc_position_reg
add wave -noupdate /tb/dut/motor4_control/abs_enc_error_reg
add wave -noupdate /tb/dut/ssi_d4
add wave -noupdate /tb/dut/ssi_c4
add wave -noupdate /tb/dut/motor4_control/crc_calc
add wave -noupdate /tb/dut/motor4_control/abs_enc_error_reg
add wave -noupdate /tb/dut/motor4_control/abs_enc_position_reg
add wave -noupdate /tb/dut/motor4_control/ssi_read_quntity
add wave -noupdate -radix unsigned /tb/dut/motor4_control/ssi_bit_cnt
add wave -noupdate -radix unsigned /tb/dut/motor4_control/state_ssi
add wave -noupdate /tb/dut/motor4_control/ssi_clk_cnt
add wave -noupdate /tb/dut/motor4_control/ssi_clk_posedge
add wave -noupdate /tb/dut/motor4_control/ssi_clk_negedge
add wave -noupdate /tb/dut/motor4_control/ssi_read_cnt
add wave -noupdate /tb/dut/motor4_control/ssi_read
add wave -noupdate /tb/dut/motor4_control/ssi_data_reg
add wave -noupdate /tb/dut/motor1_control/mosi_status
add wave -noupdate /tb/dut/motor1_control/status_bits
add wave -noupdate /tb/tb_tester/tb_tests/M1_3_Absolute_Encoder_CRC_Task/data_send
add wave -noupdate /tb/tb_tester/tb_tests/M1_3_Absolute_Encoder_CRC_Task/data
add wave -noupdate /tb/tb_tester/tb_tests/M1_3_Absolute_Encoder_CRC_Task/crc
add wave -noupdate /tb/dut/motor1_control/ssi_data_reg
add wave -noupdate /tb/dut/motor1_control/state_ssi
add wave -noupdate /tb/dut/motor1_control/crc_calc
add wave -noupdate /tb/dut/motor1_control/crc_err_cnt
add wave -noupdate -radix unsigned /tb/dut/motor1_control/ssi_bit_cnt
add wave -noupdate /tb/dut/motor1_control/abs_enc_position_reg
add wave -noupdate /tb/dut/motor1_control/ssi_d
add wave -noupdate /tb/dut/motor1_control/ssi_c
add wave -noupdate /tb/dut/motor1_control/ssi_read_quntity
add wave -noupdate /tb/dut/motor1_control/ssi_clk_cnt
add wave -noupdate /tb/dut/motor1_control/ssi_clk_negedge
add wave -noupdate /tb/dut/motor1_control/ssi_clk_posedge
add wave -noupdate /tb/dut/motor1_control/ssi_read_cnt
add wave -noupdate /tb/dut/motor1_control/ssi_read
add wave -noupdate /tb/dut/ssi_read_quntity_1
add wave -noupdate /tb/dut/ssi_read_quntity_2
add wave -noupdate /tb/dut/ssi_read_quntity_3
add wave -noupdate /tb/dut/pwm1
add wave -noupdate /tb/dut/motor1_control/state_pwm
add wave -noupdate -radix unsigned /tb/dut/motor1_control/pwm_cnt
add wave -noupdate -radix unsigned /tb/dut/motor1_control/pwm_cycle_reg
add wave -noupdate -radix unsigned /tb/dut/motor1_control/motion_control_reg
add wave -noupdate /tb/dut/led1_1
add wave -noupdate /tb/dut/led1_2
add wave -noupdate /tb/dut/led3_3
add wave -noupdate /tb/dut/led3_2
add wave -noupdate /tb/dut/led3_1
add wave -noupdate /tb/dut/led2_3
add wave -noupdate /tb/dut/led2_2
add wave -noupdate /tb/dut/led2_1
add wave -noupdate /tb/dut/lsw_2
add wave -noupdate /tb/dut/lsw_1
add wave -noupdate /tb/dut/spare1_io
add wave -noupdate /tb/dut/data_miso
add wave -noupdate /tb/dut/data_mosi
add wave -noupdate /tb/dut/registers_4mb/addr
add wave -noupdate /tb/dut/pwm4
add wave -noupdate /tb/dut/qc4a
add wave -noupdate /tb/dut/qc4b
add wave -noupdate /tb/dut/qc4i
add wave -noupdate /tb/dut/motor4_control/qci_cnt_en
add wave -noupdate -radix unsigned /tb/dut/motor4_control/qci_cnt
add wave -noupdate -radix decimal /tb/dut/motor4_control/incr_enc_error
add wave -noupdate -radix unsigned /tb/dut/incr_enc_error_reg4
add wave -noupdate -radix unsigned /tb/dut/incr_enc_def_ticks_reg4
add wave -noupdate -radix unsigned /tb/dut/incr_enc_cnt_reg4
add wave -noupdate -radix unsigned /tb/dut/abs_enc_position_reg4
add wave -noupdate -radix unsigned /tb/dut/motion_control_reg4
add wave -noupdate /tb/dut/droff1
add wave -noupdate /tb/dut/qc1a
add wave -noupdate /tb/dut/qc1b
add wave -noupdate /tb/dut/qc1i
add wave -noupdate -radix hexadecimal /tb/dut/motor1_control/incr_enc_error
add wave -noupdate -radix unsigned /tb/dut/motor1_control/incr_enc_cnt_reg
add wave -noupdate /tb/dut/motor1_control/incr_enc_def_ticks_reg
add wave -noupdate /tb/dut/motor1_control/qci_cnt
add wave -noupdate -radix hexadecimal /tb/dut/motor1_control/incr_enc_error_reg
add wave -noupdate /tb/dut/motor1_control/qci_cnt_en
add wave -noupdate /tb/dut/ssi_c1
add wave -noupdate /tb/dut/ssi_d1
add wave -noupdate /tb/dut/motor1_control/ssi_clk_cnt
add wave -noupdate /tb/dut/motor1_control/ssi_clk_posedge
add wave -noupdate /tb/dut/motor1_control/ssi_clk_negedge
add wave -noupdate /tb/dut/motor1_control/state_ssi
add wave -noupdate /tb/dut/motor1_control/ssi_bit_cnt
add wave -noupdate /tb/dut/motor1_control/ssi_read_cnt
add wave -noupdate /tb/dut/motor1_control/ssi_read
add wave -noupdate /tb/dut/motor1_control/ssi_data_reg
add wave -noupdate /tb/dut/motor1_control/ssi_read_quntity
add wave -noupdate /tb/dut/motor1_control/abs_enc_position_reg
add wave -noupdate /tb/dut/nfault1
add wave -noupdate /tb/dut/nfault2
add wave -noupdate /tb/dut/nfault3
add wave -noupdate /tb/dut/nfault4
add wave -noupdate /tb/dut/fgout1
add wave -noupdate /tb/dut/fgout2
add wave -noupdate /tb/dut/fgout3
add wave -noupdate /tb/dut/fgout4
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {24183564070 ps} 0} {{Cursor 2} {148969480 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 574
configure wave -valuecolwidth 97
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {495719700 ps}
