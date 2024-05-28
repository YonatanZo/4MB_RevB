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
    POS_0     : OUT    STD_LOGIC_VECTOR(25 DOWNTO 0); -- Position output for BISS_Master 0
    POS_1     : OUT    STD_LOGIC_VECTOR(25 DOWNTO 0); -- Position output for BISS_Master 1
    POS_2     : OUT    STD_LOGIC_VECTOR(25 DOWNTO 0); -- Position output for BISS_Master 2
    ERR_0     : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0); -- ERR counter for BISS_Master 0
    ERR_1     : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0); -- ERR counter for BISS_Master 1
    ERR_2     : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0); -- ERR counter for BISS_Master 2
    WARN_0    : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0); -- WARN counter for BISS_Master 0
    WARN_1    : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0); -- WARN counter for BISS_Master 1
    WARN_2    : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0); -- WARN counter for BISS_Master 2
    CRC_0     : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0); -- CRC error counter for BISS_Master 0
    CRC_1     : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0); -- CRC error counter for BISS_Master 1
    CRC_2     : OUT    STD_LOGIC_VECTOR(15 DOWNTO 0)  -- CRC error counter for BISS_Master 2
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
  TYPE state_type IS (IDLE, START_M, WAIT_M);
  SIGNAL state       : state_type;       -- Current state of the FSM
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
  SIGNAL crc_counter_0  : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
  SIGNAL crc_counter_1  : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
  SIGNAL crc_counter_2  : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
  SIGNAL err_counter_0  : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
  SIGNAL err_counter_1  : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
  SIGNAL err_counter_2  : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
  SIGNAL warn_counter_0 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
  SIGNAL warn_counter_1 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
  SIGNAL warn_counter_2 : STD_LOGIC_VECTOR(15 DOWNTO 0) := (others => '0');
  SIGNAL rdy_0_div      : STD_LOGIC;
  SIGNAL rdy_0_f    : STD_LOGIC;
  SIGNAL rdy_1_div      : STD_LOGIC;
  SIGNAL rdy_1_f    : STD_LOGIC;
  SIGNAL rdy_2_div      : STD_LOGIC;
  SIGNAL rdy_2_f    : STD_LOGIC;
  SIGNAL busy_bus : STD_LOGIC_VECTOR(2 DOWNTO 0);
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
    err_counter_0 <= (others => '0');
    err_counter_1 <= (others => '0');
    err_counter_2 <= (others => '0');
    warn_counter_0 <= (others => '0');
    warn_counter_1 <= (others => '0');
    warn_counter_2 <= (others => '0');
  elsif rising_edge(clk) then
    -- Update CRC, ERR, and WARN counters based on the RDY signals
    if rdy_0_div = '1' then
      if crc_err_0 = '1' then
        crc_counter_0 <= std_logic_vector(unsigned(crc_counter_0) + 1);
      end if;
      if err_0_f = '1' then
        err_counter_0 <= std_logic_vector(unsigned(err_counter_0) + 1);
      end if;
      if warn_0_f = '1' then
        warn_counter_0 <= std_logic_vector(unsigned(warn_counter_0) + 1);
      end if;
    end if;

    if rdy_1_div = '1' then
      if crc_err_1 = '1' then
        crc_counter_1 <= std_logic_vector(unsigned(crc_counter_1) + 1);
      end if;
      if err_1_f = '1' then
        err_counter_1 <= std_logic_vector(unsigned(err_counter_1) + 1);
      end if;
      if warn_1_f = '1' then
        warn_counter_1 <= std_logic_vector(unsigned(warn_counter_1) + 1);
      end if;
    end if;

    if rdy_2_div = '1' then
      if crc_err_2 = '1' then
        crc_counter_2 <= std_logic_vector(unsigned(crc_counter_2) + 1);
      end if;
      if err_2_f = '1' then
        err_counter_2 <= std_logic_vector(unsigned(err_counter_2) + 1);
      end if;
      if warn_2_f = '1' then
        warn_counter_2 <= std_logic_vector(unsigned(warn_counter_2) + 1);
      end if;
    end if;
  end if;
end process;

-- FSM to manage BISS_Masters
process(clk, reset_n)
begin
  if reset_n = '0' then
    -- Reset FSM state and control signals
    state <= IDLE;
    start_m1 <= '0';
    start_m2 <= '0';
    start_m3 <= '0';
    rdy_0_sig <= '0';
    rdy_1_sig <= '0';
    rdy_2_sig <= '0';
  elsif rising_edge(clk) then
    case state is
      when IDLE =>
        -- Initialize control signals and transition to START_M state
        start_m1 <= '0';
        start_m2 <= '0';
        start_m3 <= '0';
        state <= START_M;
      when START_M =>
        -- Start all BISS_Masters and transition to WAIT_M state
        start_m1 <= '1';
        start_m2 <= '1';
        start_m3 <= '1';
        state <= WAIT_M;
      when WAIT_M =>
        -- Stop starting signals and check RDY signals
        start_m1 <= '0';
        start_m2 <= '0';
        start_m3 <= '0';
        if rdy_0 = '1' then
          rdy_0_sig <= '1';
        end if;
        if rdy_1 = '1' then
          rdy_1_sig <= '1';
        end if;
        if rdy_2 = '1' then
          rdy_2_sig <= '1';
        end if;
        -- Transition back to IDLE when all RDY signals are set
        if busy_bus /= "111" then
          rdy_0_sig <= '0';
          rdy_1_sig <= '0';
          rdy_2_sig <= '0';
          state <= IDLE;
        else 
          state <= WAIT_M;
        end if;
      when others =>
        state <= IDLE;
    end case;
  end if;
end process;
busy_bus <= busy_0 & busy_1 & busy_2;
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

-- Combine outputs
POS_0 <= pos_0_f;
POS_1 <= pos_1_f;
POS_2 <= pos_2_f;

ERR_0 <= err_counter_0;
ERR_1 <= err_counter_1;
ERR_2 <= err_counter_2;

WARN_0 <= warn_counter_0;
WARN_1 <= warn_counter_1;
WARN_2 <= warn_counter_2;

CRC_0 <= crc_counter_0;
CRC_1 <= crc_counter_1;
CRC_2 <= crc_counter_2;

END logic;
