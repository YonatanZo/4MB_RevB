LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.Numeric_Std.all;
ENTITY adc_manger IS
  PORT (
    clk      : IN  STD_LOGIC;
    reset_n  : IN  STD_LOGIC;
    scl      : INOUT  STD_LOGIC;
    sda      : INOUT  STD_LOGIC;
    ADC0_Voltage_A : out STD_LOGIC_VECTOR(31 DOWNTO 0);
    ADC0_Voltage_B : out STD_LOGIC_VECTOR(31 DOWNTO 0);
    ADC0_Voltage_C : out STD_LOGIC_VECTOR(31 DOWNTO 0);
    ADC0_Voltage_D : out STD_LOGIC_VECTOR(31 DOWNTO 0);
    ADC1_Voltage_A : out STD_LOGIC_VECTOR(31 DOWNTO 0);
    ADC1_Voltage_B : out STD_LOGIC_VECTOR(31 DOWNTO 0);
    ADC1_Voltage_C : out STD_LOGIC_VECTOR(31 DOWNTO 0);
    ADC1_Voltage_D : out STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END adc_manger;

ARCHITECTURE behavior OF adc_manger IS
  TYPE machine IS (
  S_IDLE,
  S_BUS_CURR,
  S_GET_CURR,
  S_BUS_VOLT, 
  S_GET_VOLT
	);
  SIGNAL state         : machine;                        --state machine

  SIGNAL scl_curr : std_LOGIC := '0';
  SIGNAL sda_curr : std_LOGIC := '0';
  SIGNAL scl_volt : std_LOGIC := '0';
  SIGNAL sda_volt : std_LOGIC := '0';
  SIGNAL curr_start : std_LOGIC := '0';
  SIGNAL curr_busy : std_LOGIC := '0';
  SIGNAL volt_busy_f : std_LOGIC := '0';
  SIGNAL curr_busy_f : std_LOGIC := '0';
  SIGNAL volt_start : std_LOGIC := '0';
  SIGNAL volt_busy : std_LOGIC := '0'; 
  SIGNAL sel : std_LOGIC := '0'; 
  COMPONENT i2c_top
	GENERIC ( DEV_ID : STD_LOGIC_VECTOR(6 DOWNTO 0) := b"0010000" );
	PORT
	(
		clk		:	 IN STD_LOGIC;
		reset_n		:	 IN STD_LOGIC;
		scl		:	 INOUT STD_LOGIC;
		sda		:	 INOUT STD_LOGIC;
		START		:	 IN STD_LOGIC;
		BUSY		:	 OUT STD_LOGIC;
		AIN0		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		AIN1		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		AIN2		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		AIN3		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		AIN4		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		AIN5		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		AIN6		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		AIN7		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;


BEGIN


  Current_ADC_inst : i2c_top
    generic map (
      DEV_ID => "0010010"
    )
    PORT MAP (
      clk         => clk,
      reset_n     => reset_n,
      scl         => scl, --scl_curr
      sda         => sda, --sda_curr
      START       => curr_start,
      BUSY        => curr_busy,
      AIN0        => ADC0_Voltage_A(15 downto 0),
      AIN1        => ADC0_Voltage_A(31 downto 16),
      AIN2        => ADC0_Voltage_B(15 downto 0),
      AIN3        => ADC0_Voltage_B(31 downto 16),
      AIN4        => ADC0_Voltage_C(15 downto 0),
      AIN5        => ADC0_Voltage_C(31 downto 16),
      AIN6        => ADC0_Voltage_D(15 downto 0),
      AIN7        => ADC0_Voltage_D(31 downto 16)
    );

    Voltage_ADC_inst : i2c_top
    generic map (
      DEV_ID => "0010101"
    )
    PORT MAP (
      clk         => clk,
      reset_n     => reset_n,
      scl         => scl_volt,
      sda         => sda_volt,
      START       => volt_start,
      BUSY        => volt_busy,
      AIN0        => ADC1_Voltage_A(15 downto 0),
      AIN1        => ADC1_Voltage_A(31 downto 16),
      AIN2        => ADC1_Voltage_B(15 downto 0),
      AIN3        => ADC1_Voltage_B(31 downto 16),
      AIN4        => ADC1_Voltage_C(15 downto 0),
      AIN5        => ADC1_Voltage_C(31 downto 16),
      AIN6        => ADC1_Voltage_D(15 downto 0),
      AIN7        => ADC1_Voltage_D(31 downto 16)
    );

    PROCESS (state,sda,scl,scl_curr,sda_curr,scl_volt,sda_volt)
    BEGIN

        CASE state IS
          WHEN S_IDLE =>
            sel <= '0';
          WHEN S_BUS_CURR =>
            sel <= '0';
          WHEN S_GET_CURR =>
            sel <= '0';
          WHEN S_BUS_VOLT =>
            sel <= '1';
          WHEN S_GET_VOLT =>
            sel <= '1';
          WHEN others =>
            sel <= '0';
        end case;
    end process;

    process(clk, reset_n)
    begin
        if reset_n = '0' then
            scl <= 'Z';
            sda <= 'Z';
        elsif rising_edge(clk) then
            if sel = '0' then
                scl <= scl_curr;
                sda <= sda_curr;
            else
                scl <= scl_volt;
                sda <= sda_volt;
            end if;
        end if;
    end process;

    -- Connect shared bus to the selected controller
    scl_curr <= scl when sel = '0' else 'Z';
    sda_curr <= sda when sel = '0' else 'Z';
    scl_volt <= scl when sel = '1' else 'Z';
    sda_volt <= sda when sel = '1' else 'Z';


  PROCESS (clk, reset_n)
  BEGIN
    IF reset_n = '0' THEN
      state <= S_IDLE;
      volt_start <= '0';
      curr_start <= '0';
    ELSIF rising_edge(clk) THEN  
    curr_busy_f <= curr_busy;
    volt_busy_f <= volt_busy;   
      CASE state IS
        WHEN S_IDLE =>
          volt_start <= '0';
          curr_start <= '0';
          state <= S_BUS_CURR;
        WHEN S_BUS_CURR =>
          state <= S_GET_CURR;
        WHEN S_GET_CURR =>
          if curr_busy = '0' and curr_busy_f = '0' then 
            curr_start <= '1';
          else 
            curr_start <= '0';
          end if;
          if curr_busy = '0' and curr_busy_f = '1' then
            curr_start <= '0'; 
            state <= S_BUS_VOLT;
          end if;
        WHEN S_BUS_VOLT =>
          state <= S_GET_VOLT;
        WHEN S_GET_VOLT =>
          if volt_busy = '0' and volt_busy_f = '0' then 
            volt_start <= '1';
          else 
            volt_start <= '0';
          end if;
          if volt_busy = '0' and volt_busy_f = '1' then
            volt_start <= '0'; 
            state <= S_BUS_CURR;
          end if;
        WHEN others =>
          null;
      end case;
    end if;
  end process;
END behavior;