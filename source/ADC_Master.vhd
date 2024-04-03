LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
ENTITY ADC_Master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
	bus_clk   : INTEGER := 400_000); 
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
	AIN0   : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);
	AIN1   : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);
	AIN2   : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);
	AIN3   : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);
	AIN4   : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);
	AIN5   : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);
	AIN6   : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);
	AIN7   : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0);	
	debug : OUT     STD_LOGIC_VECTOR(7 DOWNTO 0);	
	clk_1MHz : OUT     STD_LOGIC;	
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END ADC_Master;

ARCHITECTURE logic OF ADC_Master IS



  COMPONENT ads_master
	GENERIC ( input_clk : INTEGER := 50000000; addr : STD_LOGIC_VECTOR(6 DOWNTO 0) := b"0010000"; bus_clk : INTEGER := 400000 );
	PORT
	(
		clk		:	 IN STD_LOGIC;
		reset_n		:	 IN STD_LOGIC;
		ena		:	 IN STD_LOGIC;
		rw		:	 IN STD_LOGIC;
		burst		:	 IN STD_LOGIC;
		burst_len		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		data_wr		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		reg_adrr		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		busy		:	 OUT STD_LOGIC;
		rd_rdy		:	 OUT STD_LOGIC;
		data_rd		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		debug		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		ack_error		:	 OUT STD_LOGIC;
		sda		:	 INOUT STD_LOGIC;
		scl		:	 INOUT STD_LOGIC
	);
END COMPONENT;
  CONSTANT SEQUENCE_CFG_ADDR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"10";
  CONSTANT OPMODE_CFG_ADDR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"04";
  CONSTANT PIN_CFG_ADDR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"05";
  CONSTANT AUTO_SEQ_CH_SEL_ADDR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"12";
  CONSTANT OP_SIN_REG_RD : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"10";  --Single register read
  CONSTANT OP_SIN_REG_WR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"08"; --Single register write
  CONSTANT OP_CON_REG_RD : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"30";  --Reading a continuous block of registers
  CONSTANT OP_CON_REG_WR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"28";  --Writing a continuous block of registers
  CONSTANT DEV_ID : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010000";  --Writing a continuous block of registers
  TYPE machine IS (
  S_IDLE,
  S_CONFIG_ADC,
  S_WAIT_BUSY,
  S_DATA_REQ,
  S_WAIT_WR_DONE,
  S_GET_DATA,
  S_RESTART_RD,
  S_WAIT_RD_RDY
	);
  SIGNAL state         : machine;                        --state machine
  SIGNAL data_clk      : STD_LOGIC;                      --data clock for sda
  SIGNAL data_clk_prev : STD_LOGIC;                      --data clock during previous system clock
  SIGNAL scl_ena       : STD_LOGIC := '0';               --enables internal scl to output
  SIGNAL sda_int       : STD_LOGIC := '1';               --internal sda
  SIGNAL sda_ena_n     : STD_LOGIC;                      --enables internal sda to output
  SIGNAL addr_rw       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --latched in address and read/write
  SIGNAL data_tx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --latched in data to write to slave
  SIGNAL data_rx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --data received from slave
  SIGNAL bit_cnt       : INTEGER RANGE 0 TO 7 := 7;      --tracks bit number in transaction
  SIGNAL stretch       : STD_LOGIC := '0';               --identifies if slave is stretching scl
  SIGNAL DATA_BUFFER       : STD_LOGIC_VECTOR(127 DOWNTO 0);   
  SIGNAL i2c_ena      : STD_LOGIC;
  SIGNAL i2c_addr     : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL i2c_data_wr  : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL i2c_rw       : STD_LOGIC;
  SIGNAL data_pointer : INTEGER RANGE 0 TO 8; -- Define the upper range according to your design needs

  SIGNAL reg_cnt  : INTEGER RANGE 0 TO 16; -- Define the upper range according to your design needs
  SIGNAL ena_signal        : STD_LOGIC;
  SIGNAL busy_prev         : STD_LOGIC := '0';
  SIGNAL addr_signal       : STD_LOGIC_VECTOR(6 DOWNTO 0);
  SIGNAL rw_signal         : STD_LOGIC;
  SIGNAL data_wr_signal    : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL i2c_busy          : STD_LOGIC;
  SIGNAL data_rd_signal    : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL reg_adrr	: STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL ack_error_signal  : STD_LOGIC;
  SIGNAL burst  : STD_LOGIC;
  SIGNAL burst_len     : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL reg_addr          : STD_LOGIC_VECTOR(7 DOWNTO 0);
  signal rd_rdy : STD_LOGIC;
  signal busy_cnt :INTEGER RANGE 0 TO 127:= 0; 
  signal busy_fall : STD_LOGIC:= '0';
  signal i2c_busy_f :STD_LOGIC;
BEGIN

ads_master_inst: ads_master
generic map (
  input_clk => 50000000,
  addr      => DEV_ID,
  bus_clk   => 400000
)
port map (
  clk       => clk,                 -- system clock
  reset_n   => reset_n,             -- active low reset
  ena       => i2c_ena,             -- latch in command
  rw        => i2c_rw,              -- '0' is write, '1' is read
  burst     => burst,               -- '1' burst mode enable
  burst_len => burst_len,           -- Burst length
  data_wr   => i2c_data_wr,         -- data to write to slave
  reg_adrr  => reg_adrr,            -- address to write/read from/to slave
  busy      => i2c_busy,            -- indicates transaction in progress
  rd_rdy    => rd_rdy,              -- indicates burst read data is ready
  data_rd   => data_rd_signal,      -- data read from slave
  debug =>debug,
  ack_error => ack_error_signal,    -- flag if improper acknowledge from slave
  sda       => sda,                 -- serial data output of i2c bus
  scl       => scl                  -- serial clock output of i2c bus
);

AIN0 <= DATA_BUFFER(15 downto 0);
AIN1 <= DATA_BUFFER(31 downto 16);
AIN2 <= DATA_BUFFER(47 downto 32);
AIN3 <= DATA_BUFFER(63 downto 48);
AIN4 <= DATA_BUFFER(79 downto 64);
AIN5 <= DATA_BUFFER(95 downto 80);
AIN6 <= DATA_BUFFER(111 downto 96);
AIN7 <= DATA_BUFFER(127 downto 112);

  PROCESS(clk, reset_n,busy_prev,i2c_busy,data_rd_signal)
  BEGIN
	IF(reset_n = '0') THEN                 --reset asserted
	state <= S_IDLE;                      --return to initial state
	reg_cnt <= 0;
	burst_len <= "00000000";
	burst <= '0';
	reg_cnt <= 0;
	i2c_rw <= '0';
	i2c_ena  <= '0';
	reg_addr <= (others => '0');
	i2c_data_wr <= (others => '0');
	data_pointer <= 0;
	busy_cnt <= 0;
	ELSIF rising_edge(clk) THEN
		i2c_busy_f <= i2c_busy;
		CASE state IS
			WHEN S_IDLE =>
				busy_cnt <= 0;
				reg_cnt <= 0;
				burst_len <= "00000000";
				state <= S_CONFIG_ADC;
				burst <= '0';
				reg_cnt <= 0;
				i2c_rw <= '0';
				i2c_ena  <= '0';
				reg_addr <= (others => '0');
				i2c_data_wr <= (others => '0');
				data_pointer <= 0;
				busy_fall <= '0';
			WHEN S_CONFIG_ADC => 
				burst <= '0';
				i2c_rw <= '0';
				CASE reg_cnt IS                            
				WHEN 0 =>  
					i2c_ena  <= '1';
					reg_addr <= SEQUENCE_CFG_ADDR;
					i2c_data_wr <= (others => '0');
					state <= S_WAIT_BUSY;
				WHEN 1 =>  
					i2c_ena  <= '1';                                
					reg_addr <= OPMODE_CFG_ADDR;
					i2c_data_wr <= (others => '0');
					state <= S_WAIT_BUSY;
				WHEN 2 =>                                
					i2c_ena  <= '1';
					reg_addr <=PIN_CFG_ADDR;
					i2c_data_wr <= (others => '0');
					state <= S_WAIT_BUSY;
				WHEN 3 =>
					i2c_ena  <= '1';                                
					reg_addr <=AUTO_SEQ_CH_SEL_ADDR;
					i2c_data_wr <= x"ff";
					state <= S_WAIT_BUSY;
				WHEN 4 => 
					i2c_ena  <= '1';                               
					reg_addr <=SEQUENCE_CFG_ADDR;
					i2c_data_wr <= x"01";
					state <= S_WAIT_BUSY;
				WHEN 5 =>                                
					i2c_ena  <= '1';
					reg_addr <=SEQUENCE_CFG_ADDR;
					i2c_data_wr <= x"11";
					state <= S_WAIT_BUSY;
				WHEN 6 =>     
					i2c_ena <= '0';
					state <= S_DATA_REQ;
				WHEN others =>
					null;
				END CASE;

			WHEN S_WAIT_BUSY =>
				
				if (i2c_busy = '0' and i2c_busy_f = '1') then
					busy_fall <= '1';
					i2c_ena <= '0';
				end if;

				if (busy_fall = '1') then
					if (busy_cnt = 127) then
						reg_cnt <= reg_cnt +1;
						busy_fall <= '0';
						state <= S_CONFIG_ADC;
						busy_cnt <= 0;
					else 
						busy_cnt <= busy_cnt +1;
						state <= S_WAIT_BUSY;
					end if;
				else
					state <= S_WAIT_BUSY;
				end if;
			WHEN S_DATA_REQ => 
				data_pointer <= 0;
				i2c_ena <= '1';
				burst <= '1';
				i2c_rw <= '1';  
				burst_len <= "00001000"; -- 8 registers
				if data_pointer = 8 then 
					data_pointer <= 0;
					reg_adrr <= x"A0";
					state <= S_RESTART_RD;
				end if;
				state <= S_WAIT_RD_RDY;
				
			WHEN S_WAIT_RD_RDY => 
				IF rd_rdy = '1' THEN
					state <= S_DATA_REQ ;   
					data_pointer <= data_pointer +1;
					DATA_BUFFER(8*data_pointer+7 downto data_pointer*8) <= data_rd_signal;
				ELSE 
					state <= S_WAIT_RD_RDY ;   
				END IF;
			WHEN S_RESTART_RD =>  
				  i2c_ena <= '0';                                                    
				  state <= S_DATA_REQ; 
			WHEN others =>
						null;	
			END CASE;
			
		END IF;
END PROCESS;
	
END logic;