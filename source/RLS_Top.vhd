LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;


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
COMPONENT RLS_Master
	GENERIC ( input_clk : INTEGER := 100000000; bus_clk : INTEGER := 1000000 );
	PORT
	(
		clk		:	 IN STD_LOGIC;
		reset_n		:	 IN STD_LOGIC;
		RLS_MA		:	 OUT STD_LOGIC;
		RLS_SLO		:	 IN STD_LOGIC;
		POS_REG		:	 OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		ERR_REG		:	 OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
END COMPONENT;
BEGIN
M1_ENC: RLS_Master
  GENERIC MAP (
    input_clk => input_clk,
    bus_clk   => bus_clk 
  )
  PORT MAP (
    clk       => clk,
    reset_n   => reset_n,
    RLS_MA     => RLS_MA_0,
    RLS_SLO       => RLS_SLO_0,
    POS_REG       => POS_REG_0,
    ERR_REG      => ERR_REG_0
  );

  M2_ENC: RLS_Master
  GENERIC MAP (
    input_clk => input_clk,
    bus_clk   => bus_clk 
  )
  PORT MAP (
    clk       => clk,
    reset_n   => reset_n,
    RLS_MA     => RLS_MA_1,
    RLS_SLO       => RLS_SLO_1,
    POS_REG       => POS_REG_1,
    ERR_REG      => ERR_REG_1
  );

  M3_ENC: RLS_Master
  GENERIC MAP (
    input_clk => input_clk,
    bus_clk   => bus_clk 
  )
  PORT MAP (
    clk       => clk,
    reset_n   => reset_n,
    RLS_MA     => RLS_MA_2,
    RLS_SLO       => RLS_SLO_2,
    POS_REG       => POS_REG_2,
    ERR_REG      => ERR_REG_2
  );
END logic;
