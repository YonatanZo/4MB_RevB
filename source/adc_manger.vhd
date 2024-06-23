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
  constant CURR_ADC_ID :  STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010010"; 
  constant VOLT_ADC_ID :  STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010101";  
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
  SIGNAL start : std_LOGIC := '0';
  SIGNAL busy : std_LOGIC := '0';
  SIGNAL busy_f : std_LOGIC := '0';
  -- SIGNAL sel : std_LOGIC := '0'; 
  SIGNAL DEV_ID_reg : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010000"; 
  SIGNAL AIN0 : STD_LOGIC_VECTOR(15 DOWNTO 0) ; 
  SIGNAL AIN1 : STD_LOGIC_VECTOR(15 DOWNTO 0) ; 
  SIGNAL AIN2 : STD_LOGIC_VECTOR(15 DOWNTO 0) ; 
  SIGNAL AIN3 : STD_LOGIC_VECTOR(15 DOWNTO 0) ; 
  SIGNAL AIN4 : STD_LOGIC_VECTOR(15 DOWNTO 0) ; 
  SIGNAL AIN5 : STD_LOGIC_VECTOR(15 DOWNTO 0) ; 
  SIGNAL AIN6 : STD_LOGIC_VECTOR(15 DOWNTO 0) ; 
  SIGNAL AIN7 : STD_LOGIC_VECTOR(15 DOWNTO 0) ; 
  COMPONENT i2c_top
	PORT
	(
		clk		:	 IN STD_LOGIC;
		reset_n		:	 IN STD_LOGIC;
		scl		:	 INOUT STD_LOGIC;
		sda		:	 INOUT STD_LOGIC;
    DEV_ID : IN STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010000" ;
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


  ADC_inst : i2c_top

    PORT MAP (
      clk         => clk,
      reset_n     => reset_n,
      scl         => scl, --scl_curr
      sda         => sda, --sda_curr
      DEV_ID      => DEV_ID_reg,
      START       => start,
      BUSY        => busy,
      AIN0        => AIN0,
      AIN1        => AIN1,
      AIN2        => AIN2,
      AIN3        => AIN3,
      AIN4        => AIN4,
      AIN5        => AIN5,
      AIN6        => AIN6,
      AIN7        => AIN7
    );


    PROCESS (state,sda,scl,scl_curr,sda_curr,scl_volt,sda_volt)
    BEGIN

        CASE state IS
          WHEN S_IDLE =>
            DEV_ID_reg <=CURR_ADC_ID;
          WHEN S_BUS_CURR =>
            DEV_ID_reg <=CURR_ADC_ID;
          WHEN S_GET_CURR =>
            DEV_ID_reg <=CURR_ADC_ID;
          WHEN S_BUS_VOLT =>
            DEV_ID_reg <=VOLT_ADC_ID;
          WHEN S_GET_VOLT =>
            DEV_ID_reg <=VOLT_ADC_ID;
          WHEN others =>
            DEV_ID_reg <=CURR_ADC_ID;
        end case;
    end process;




  PROCESS (clk, reset_n)
  BEGIN
    IF reset_n = '0' THEN
      state <= S_IDLE;
      start <= '0';
    ELSIF rising_edge(clk) THEN  
    busy_f <= busy;
  
      CASE state IS
        WHEN S_IDLE =>
          start <= '0';
          state <= S_BUS_CURR;
        WHEN S_BUS_CURR =>
          state <= S_GET_CURR;
        WHEN S_GET_CURR =>
          if busy = '0' and busy_f = '0' then 
            start <= '1';
          else 
            start <= '0';
          end if;
          if busy = '0' and busy_f = '1' then
            start <= '0'; 
            ADC0_Voltage_A(15 downto 0)<= AIN0;
            ADC0_Voltage_A(31 downto 16)<= AIN1;
            ADC0_Voltage_B(15 downto 0)<= AIN2;
            ADC0_Voltage_B(31 downto 16)<= AIN3;
            ADC0_Voltage_C(15 downto 0)<= AIN4;
            ADC0_Voltage_C(31 downto 16)<= AIN5;
            ADC0_Voltage_D(15 downto 0)<= AIN6;
            ADC0_Voltage_D(31 downto 16)<= AIN7;
            state <= S_BUS_VOLT;
          end if;
        WHEN S_BUS_VOLT =>
          state <= S_GET_VOLT;
        WHEN S_GET_VOLT =>
          if busy = '0' and busy_f = '0' then 
            start <= '1';
          else 
            start <= '0';
          end if;
          if busy = '0' and busy_f = '1' then
            start <= '0'; 
            ADC1_Voltage_A(15 downto 0)<= AIN0;
            ADC1_Voltage_A(31 downto 16)<= AIN1;
            ADC1_Voltage_B(15 downto 0)<= AIN2;
            ADC1_Voltage_B(31 downto 16)<= AIN3;
            ADC1_Voltage_C(15 downto 0)<= AIN4;
            ADC1_Voltage_C(31 downto 16)<= AIN5;
            ADC1_Voltage_D(15 downto 0)<= AIN6;
            ADC1_Voltage_D(31 downto 16)<= AIN7;
            state <= S_BUS_CURR;
          end if;
        WHEN others =>
          null;
      end case;
    end if;
  end process;
END behavior;