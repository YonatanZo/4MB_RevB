LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;

ENTITY RLS_Top IS
  GENERIC(
    input_clk : INTEGER := 100_000_000; -- input clock speed from user logic in Hz
    bus_clk   : INTEGER := 1_000_000    -- bus clock speed in Hz
  ); 
  PORT(
    clk       : IN     STD_LOGIC;        -- system clock
    reset_n   : IN     STD_LOGIC;        -- active low reset
    RLS_MA_0  : OUT    STD_LOGIC;        -- Master clock output for BISS_Master 0
    RLS_MA_1  : OUT    STD_LOGIC;        -- Master clock output for BISS_Master 1
    RLS_MA_2  : OUT    STD_LOGIC;        -- Master clock output for BISS_Master 2
    RLS_SLO_0 : IN     STD_LOGIC;        -- Serial clock input for BISS_Master 0
    RLS_SLO_1 : IN     STD_LOGIC;        -- Serial clock input for BISS_Master 1
    RLS_SLO_2 : IN     STD_LOGIC;        -- Serial clock input for BISS_Master 2
    POS_REG_0     : OUT    STD_LOGIC_VECTOR(31 DOWNTO 0); -- Position output for BISS_Master 0
    POS_REG_1     : OUT    STD_LOGIC_VECTOR(31 DOWNTO 0); -- Position output for BISS_Master 1
    POS_REG_2     : OUT    STD_LOGIC_VECTOR(31 DOWNTO 0); -- Position output for BISS_Master 2
    ERR_REG_0     : OUT    STD_LOGIC_VECTOR(31 DOWNTO 0); -- ERR counter for BISS_Master 0
    ERR_REG_1     : OUT    STD_LOGIC_VECTOR(31 DOWNTO 0); -- ERR counter for BISS_Master 1
    ERR_REG_2     : OUT    STD_LOGIC_VECTOR(31 DOWNTO 0) -- ERR counter for BISS_Master 2

  );                  
END RLS_Top;

ARCHITECTURE logic OF RLS_Top IS

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
  SIGNAL state_m1       : state_type;       -- Current state of the FSM
  SIGNAL state_m2       : state_type;       -- Current state of the FSM
  SIGNAL state_m3       : state_type;       -- Current state of the FSM
  SIGNAL start_m1    : STD_LOGIC := '0'; -- Start signal for BISS_Master 1
  SIGNAL start_m2    : STD_LOGIC := '0'; -- Start signal for BISS_Master 2
  SIGNAL start_m3    : STD_LOGIC := '0'; -- Start signal for BISS_Master 3

  -- Intermediate signals for position, error, and warning outputs from BISS_Master instances
  SIGNAL pos_0_f     : STD_LOGIC_VECTOR(25 DOWNTO 0);
  SIGNAL pos_1_f     : STD_LOGIC_VECTOR(25 DOWNTO 0);
  SIGNAL pos_2_f     : STD_LOGIC_VECTOR(25 DOWNTO 0);
  SIGNAL err_0_f     : STD_LOGIC;
  SIGNAL err_1_f     : STD_LOGIC;
  SIGNAL err_2_f     : STD_LOGIC;
  SIGNAL warn_0_f    : STD_LOGIC;
  SIGNAL warn_1_f    : STD_LOGIC;
  SIGNAL warn_2_f    : STD_LOGIC;
  SIGNAL crc_err_0   : STD_LOGIC;
  SIGNAL crc_err_1   : STD_LOGIC;
  SIGNAL crc_err_2   : STD_LOGIC;
  SIGNAL rdy_0       : STD_LOGIC;
  SIGNAL rdy_1       : STD_LOGIC;
  SIGNAL rdy_2       : STD_LOGIC;
  SIGNAL rdy_0_sig   : STD_LOGIC;
  SIGNAL rdy_1_sig   : STD_LOGIC;
  SIGNAL rdy_2_sig   : STD_LOGIC;
  SIGNAL busy_0      : STD_LOGIC;
  SIGNAL busy_1      : STD_LOGIC;
  SIGNAL busy_2      : STD_LOGIC;

  -- Error and warning counters for each BISS_Master instance
  SIGNAL crc_counter_0  : STD_LOGIC_VECTOR(27 DOWNTO 0) := (others => '0');
  SIGNAL crc_counter_1  : STD_LOGIC_VECTOR(27 DOWNTO 0) := (others => '0');
  SIGNAL crc_counter_2  : STD_LOGIC_VECTOR(27 DOWNTO 0) := (others => '0');
  SIGNAL rdy_counter_0  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
  SIGNAL rdy_counter_1  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
  SIGNAL rdy_counter_2  : STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
  SIGNAL rdy_0_div      : STD_LOGIC;
  SIGNAL rdy_0_f    : STD_LOGIC;
  SIGNAL rdy_1_div      : STD_LOGIC;
  SIGNAL rdy_1_f    : STD_LOGIC;
  SIGNAL rdy_2_div      : STD_LOGIC;
  SIGNAL rdy_2_f    : STD_LOGIC;
  SIGNAL sleep_100us_cnt_m1  : INTEGER RANGE 0 TO 10000 := 0;
  SIGNAL sleep_100us_cnt_m2  : INTEGER RANGE 0 TO 10000 := 0;
  SIGNAL sleep_100us_cnt_m3  : INTEGER RANGE 0 TO 10000 := 0;
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
    START     => start_m1,
    POS       => pos_0_f,
    ERR       => err_0_f,
    WARN      => warn_0_f,
    CRC_ERR   => crc_err_0,
    RDY       => rdy_0,
    BUSY      => busy_0,
    MCLK      => RLS_MA_0,
    SLO       => RLS_SLO_0
  );

-- Instantiation of BISS_Master 1
M2_ENC: BISS_Master
  GENERIC MAP (
    input_clk => input_clk,
    bus_clk   => bus_clk 
  )
  PORT MAP (
    clk       => clk,
    reset_n   => reset_n,
    START     => start_m2,
    POS       => pos_1_f,
    ERR       => err_1_f,
    WARN      => warn_1_f,
    CRC_ERR   => crc_err_1,
    RDY       => rdy_1,
    BUSY      => busy_1,
    MCLK      => RLS_MA_1,
    SLO       => RLS_SLO_1
  );

-- Instantiation of BISS_Master 2
M3_ENC: BISS_Master
  GENERIC MAP (
    input_clk => input_clk,
    bus_clk   => bus_clk 
  )
  PORT MAP (
    clk       => clk,
    reset_n   => reset_n,
    START     => start_m3,
    POS       => pos_2_f,
    ERR       => err_2_f,
    WARN      => warn_2_f,
    CRC_ERR   => crc_err_2,
    RDY       => rdy_2,
    BUSY      => busy_2,
    MCLK      => RLS_MA_2,
    SLO       => RLS_SLO_2
  );

-- CRC, ERR, and WARN error counters update process
process(clk, reset_n)
begin
  if reset_n = '0' then
    -- Reset all counters to zero on reset
    crc_counter_0 <= (others => '0');
    crc_counter_1 <= (others => '0');
    crc_counter_2 <= (others => '0');
    rdy_counter_0 <= (others => '0');
    rdy_counter_1 <= (others => '0');
    rdy_counter_2 <= (others => '0');

  elsif rising_edge(clk) then
    -- Update CRC, ERR, and WARN counters based on the RDY signals
    if rdy_0_div = '1' then
      if crc_err_0 = '1' then
        crc_counter_0 <= std_logic_vector(unsigned(crc_counter_0) + 1);
      end if;
      rdy_counter_0 <= std_logic_vector(unsigned(rdy_counter_0) + 1);
    end if;

    if rdy_1_div = '1' then
      if crc_err_1 = '1' then
        crc_counter_1 <= std_logic_vector(unsigned(crc_counter_1) + 1);
      end if;
      rdy_counter_1 <= std_logic_vector(unsigned(rdy_counter_1) + 1);
    end if;
    if rdy_2_div = '1' then
      if crc_err_2 = '1' then
        crc_counter_2 <= std_logic_vector(unsigned(crc_counter_2) + 1);
      end if;
      rdy_counter_2 <= std_logic_vector(unsigned(rdy_counter_2) + 1);
    end if;
  end if;
end process;

process(clk, reset_n)
begin
  if reset_n = '0' then
    -- Reset FSM state and control signals
    state_m1 <= IDLE;
    start_m1 <= '0';
    rdy_0_sig <= '0';
    sleep_100us_cnt_m1 <= 0;
  elsif rising_edge(clk) then
    case state_m1 is
      when IDLE =>
        sleep_100us_cnt_m1 <= 0;
        -- Initialize control signals and transition to START_M state
        start_m1 <= '0';
        state_m1 <= START_M;
      when START_M =>
        -- Start all BISS_Masters and transition to WAIT_M state
        start_m1 <= '1';
        if busy_0 = '1' then
          state_m1 <= WAIT_M;
        else 
          state_m1 <= START_M;
        end if;
      when WAIT_M =>
        -- Stop starting signals and check RDY signals
        start_m1 <= '0';
        if rdy_0 = '1' then
          rdy_0_sig <= '1';
        end if;
        -- Transition back to IDLE when all RDY signals are set
        if busy_0 = '0' then
          rdy_0_sig <= '0';
          state_m1 <= SLEEP;
        else 
          state_m1 <= WAIT_M;
        end if;
      when SLEEP =>
        if  sleep_100us_cnt_m1 = 999 then
          state_m1 <= IDLE;
          sleep_100us_cnt_m1 <= 0;
        else 
          sleep_100us_cnt_m1 <= sleep_100us_cnt_m1 +1;
          state_m1 <= SLEEP;
        end if;
      when others =>
        state_m1 <= IDLE;
    end case;
  end if;
end process;

process(clk, reset_n)
begin
  if reset_n = '0' then
    -- Reset FSM state and control signals
    state_m2 <= IDLE;
    start_m2 <= '0';
    rdy_1_sig <= '0';
    sleep_100us_cnt_m2 <= 0;
  elsif rising_edge(clk) then
    case state_m2 is
      when IDLE =>
        sleep_100us_cnt_m2 <= 0;
        -- Initialize control signals and transition to START_M state
        start_m2 <= '0';
        state_m2 <= START_M;
      when START_M =>
        -- Start all BISS_Masters and transition to WAIT_M state
        start_m2 <= '1';
        if busy_1 = '1' then
          state_m2 <= WAIT_M;
        else 
          state_m2 <= START_M;
        end if;
      when WAIT_M =>
        -- Stop starting signals and check RDY signals
        start_m2 <= '0';
        if rdy_1 = '1' then
          rdy_1_sig <= '1';
        end if;
        -- Transition back to IDLE when all RDY signals are set
        if busy_1 = '0' then
          rdy_1_sig <= '0';
          state_m2 <= SLEEP;
        else 
          state_m2 <= WAIT_M;
        end if;
      when SLEEP =>
        if  sleep_100us_cnt_m2 = 999 then
          state_m2 <= IDLE;
          sleep_100us_cnt_m2 <= 0;
        else 
          sleep_100us_cnt_m2 <= sleep_100us_cnt_m2 +1;
          state_m2 <= SLEEP;
        end if;
      when others =>
        state_m2 <= IDLE;
    end case;
  end if;
end process;

process(clk, reset_n)
begin
  if reset_n = '0' then
    -- Reset FSM state and control signals
    state_m3 <= IDLE;
    start_m3 <= '0';
    rdy_2_sig <= '0';
    sleep_100us_cnt_m3 <= 0;
  elsif rising_edge(clk) then
    case state_m3 is
      when IDLE =>
        -- Initialize control signals and transition to START_M state
        start_m3 <= '0';
        state_m3 <= START_M;
        sleep_100us_cnt_m3 <= 0;
      when START_M =>
        -- Start all BISS_Masters and transition to WAIT_M state
        start_m3 <= '1';
        if busy_2 = '1' then
          state_m3 <= WAIT_M;
        else 
          state_m3 <= START_M;
        end if;
      when WAIT_M =>
        -- Stop starting signals and check RDY signals
        start_m3 <= '0';
        if rdy_2 = '1' then
          rdy_2_sig <= '1';
        end if;
        -- Transition back to IDLE when all RDY signals are set
        if busy_2 = '0' then
          rdy_2_sig <= '0';
          state_m3 <= SLEEP;
        else 
          state_m3 <= WAIT_M;
        end if;
      when SLEEP =>
        if  sleep_100us_cnt_m3 = 999 then
          state_m3 <= IDLE;
          sleep_100us_cnt_m3 <= 0;
        else 
          sleep_100us_cnt_m3 <= sleep_100us_cnt_m3 +1;
          state_m3 <= SLEEP;
        end if;
      when others =>
        state_m3 <= IDLE;
    end case;
  end if;
end process;
-- Register RDY signal changes
process(clk)
begin
  if rising_edge(clk) then
    rdy_0_f <= rdy_0;
    rdy_1_f <= rdy_1;
    rdy_2_f <= rdy_2;
  end if;
end process;

-- Generate edge detection signals for RDY signals
rdy_0_div <= rdy_0 and (not rdy_0_f);
rdy_1_div <= rdy_1 and (not rdy_1_f);
rdy_2_div <= rdy_2 and (not rdy_2_f);

process(clk,reset_n)
begin
  if reset_n = '0' then
    POS_REG_0 <= (others => '0');
    POS_REG_1 <= (others => '0');
    POS_REG_2 <= (others => '0');
    ERR_REG_0 <= (others => '0');
    ERR_REG_1 <= (others => '0');
    ERR_REG_2 <= (others => '0');
  elsif rising_edge(clk) then
    POS_REG_0(25 downto 0)  <= pos_0_f;
    POS_REG_1(25 downto 0)  <= pos_1_f;
    POS_REG_2(25 downto 0)  <= pos_2_f;
    POS_REG_0(31 downto 26)  <= rdy_counter_0;
    POS_REG_1(31 downto 26)  <= rdy_counter_1;
    POS_REG_2(31 downto 26)  <= rdy_counter_2;
    ERR_REG_0(27 downto 0)  <= crc_counter_0;
    ERR_REG_1(27 downto 0)  <= crc_counter_1;
    ERR_REG_2(27 downto 0)  <= crc_counter_2;
    ERR_REG_0(28) <= err_0_f;
    ERR_REG_1(28) <= err_1_f;
    ERR_REG_2(28) <= err_2_f;
    ERR_REG_0(29) <= warn_0_f;
    ERR_REG_1(29) <= warn_1_f;
    ERR_REG_2(29) <= warn_2_f;
  end if;
  end process;
END logic;
