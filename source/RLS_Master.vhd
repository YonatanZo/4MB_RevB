LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY RLS_Master IS
  GENERIC(
    input_clk : INTEGER := 100_000_000; -- input clock speed from user logic in Hz
    bus_clk   : INTEGER := 1_000_000    -- bus clock speed in Hz
  ); 
  PORT(
    clk       : IN     STD_LOGIC;        -- system clock
    reset_n   : IN     STD_LOGIC;        -- active low reset
    RLS_MA  : OUT    STD_LOGIC;        -- Master clock output for BISS_Master 
    RLS_SLO : IN     STD_LOGIC;        -- Serial clock input for BISS_Master 
    POS_REG     : OUT    STD_LOGIC_VECTOR(31 DOWNTO 0); -- Position output for BISS_Master 
    ERR_REG     : OUT    STD_LOGIC_VECTOR(31 DOWNTO 0) -- ERR counter for BISS_Master 
  );                  
END RLS_Master;

ARCHITECTURE logic OF RLS_Master IS
COMPONENT clock_generator
	GENERIC ( clock_in_speed : INTEGER := 100000000; clock_out_speed : INTEGER := 100000 );
	PORT
	(
		clock_in		:	 IN STD_LOGIC;
		clock_out		:	 OUT STD_LOGIC
	);
END COMPONENT;


  COMPONENT BISS_Master
    GENERIC(
      input_clk : INTEGER := 100_000_000;
      bus_clk   : INTEGER := 1_000_000
    );
    PORT(
      clk       : IN     STD_LOGIC;
      reset_n   : IN     STD_LOGIC;
      START     : IN     STD_LOGIC;
      POS       : OUT    STD_LOGIC_VECTOR(25 DOWNTO 0);
      ERR       : OUT    STD_LOGIC;
      WARN      : OUT    STD_LOGIC;
      CRC_ERR   : OUT    STD_LOGIC;
      RDY       : OUT    STD_LOGIC;
      BUSY      : OUT    STD_LOGIC;
      MCLK      : OUT    STD_LOGIC;
      SLO       : IN     STD_LOGIC
    );
  END COMPONENT;
  -- State machine states
  TYPE state_type IS (IDLE, START_M, WAIT_M,SLEEP);
  SIGNAL state       : state_type;       -- Current state of the FSM
  SIGNAL start    : STD_LOGIC := '0'; -- Start signal for BISS_Master 1
  -- Intermediate signals for position, error, and warning outputs from BISS_Master instances
  SIGNAL pos_f     : STD_LOGIC_VECTOR(25 DOWNTO 0);
  SIGNAL err_f     : STD_LOGIC;
  SIGNAL warn_f    : STD_LOGIC;
  SIGNAL crc_err   : STD_LOGIC;
  SIGNAL rdy       : STD_LOGIC;
  SIGNAL rdy_sig   : STD_LOGIC;
  SIGNAL busy      : STD_LOGIC;
  -- Error and warning counters for each BISS_Master instance
  SIGNAL crc_counter  : STD_LOGIC_VECTOR(27 DOWNTO 0) := (others => '0');
  SIGNAL rdy_counter  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
  SIGNAL rdy_counter_ff  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
  SIGNAL last_counter  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
  SIGNAL rdy_div      : STD_LOGIC;
  SIGNAL rdy_f    : STD_LOGIC;
  SIGNAL clk_100u    : STD_LOGIC;
  SIGNAL sleep_100us_cnt_m1  : INTEGER RANGE 0 TO 10000 := 0;
BEGIN

-- Instantiation of BISS_Master 0
M1_ENC: BISS_Master
  GENERIC MAP (
    input_clk => input_clk,
    bus_clk   => bus_clk 
  )
  PORT MAP (
    clk       => clk,
    reset_n   => reset_n,
    START     => start,
    POS       => pos_f,
    ERR       => err_f,
    WARN      => warn_f,
    CRC_ERR   => crc_err,
    RDY       => rdy,
    BUSY      => busy,
    MCLK      => RLS_MA,
    SLO       => RLS_SLO
  );

  CMP_clk_100u: clock_generator
	GENERIC MAP( clock_in_speed =>100000000,
              clock_out_speed => 10000 )
	PORT MAP
	(
		clock_in		=> clk,
		clock_out		=> clk_100u
	);

-- CRC, ERR, and WARN error counters update process
process(clk, reset_n)
begin
  if reset_n = '0' then
    -- Reset all counters to zero on reset
    crc_counter <= (others => '0');
    rdy_counter <= (others => '0');
    POS_REG(25 downto 0) <= (others => '0');
  elsif rising_edge(clk) then
    -- Update CRC, ERR, and WARN counters based on the RDY signals
    if rdy_div = '1' then
      if crc_err = '1' then
        crc_counter <= std_logic_vector(unsigned(crc_counter) + 1);
      else
        rdy_counter <= std_logic_vector(unsigned(rdy_counter) + 1);
        POS_REG(25 downto 0)  <= pos_f;
      end if;
    end if;
  end if;
end process;

last_updata_counter:process(clk_100u, reset_n)
begin
  if reset_n = '0'  then
    rdy_counter_ff <= (others => '0');
    last_counter <= (others => '0');
  elsif rising_edge(clk_100u) then
    rdy_counter_ff <= rdy_counter;
    if rdy_counter_ff = rdy_counter then
        last_counter <= std_logic_vector(unsigned(last_counter) + 1);
    else
        last_counter <= (others => '0');
    end if;

  end if;
end process;

process(clk, reset_n)
begin
  if reset_n = '0' then
    -- Reset FSM state and control signals
    state <= IDLE;
    start <= '0';
    rdy_sig <= '0';
    sleep_100us_cnt_m1 <= 0;
  elsif rising_edge(clk) then
    case state is
      when IDLE =>
        sleep_100us_cnt_m1 <= 0;
        -- Initialize control signals and transition to START_M state
        start <= '0';
        state <= START_M;
      when START_M =>
        -- Start all BISS_Masters and transition to WAIT_M state
        start <= '1';
        if busy = '1' then
          state <= WAIT_M;
        else 
          state <= START_M;
        end if;
      when WAIT_M =>
        -- Stop starting signals and check RDY signals
        start <= '0';
        if busy = '0' then
          state <= SLEEP;
        else 
          state <= WAIT_M;
        end if;
      when SLEEP =>
        if  sleep_100us_cnt_m1 = 999 then
          state <= IDLE;
          sleep_100us_cnt_m1 <= 0;
        else 
          sleep_100us_cnt_m1 <= sleep_100us_cnt_m1 +1;
          state <= SLEEP;
        end if;
      when others =>
        state <= IDLE;
    end case;
  end if;
end process;



process(clk)
begin
  if rising_edge(clk) then
    rdy_f <= rdy;
  end if;
end process;

-- Generate edge detection signals for RDY signals
rdy_div <= rdy and (not rdy_f);


process(clk,reset_n)
begin
  if reset_n = '0' then
    POS_REG(31 downto 26)   <= (others => '0');
    ERR_REG <= (others => '0');
  elsif rising_edge(clk) then
    POS_REG(31 downto 26)  <= last_counter;
    ERR_REG(27 downto 0)  <= crc_counter;
    ERR_REG(28) <= err_f;
    ERR_REG(29) <= warn_f;
  end if;
  end process;
END logic;
