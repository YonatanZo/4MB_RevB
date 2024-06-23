LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.Numeric_Std.all;
ENTITY i2c_top IS

  PORT (
    clk      : IN  STD_LOGIC;
    reset_n  : IN  STD_LOGIC;
    scl      : INOUT  STD_LOGIC;
    sda      : INOUT  STD_LOGIC;
    DEV_ID   : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
    START    : IN  STD_LOGIC;
    BUSY     : OUT  STD_LOGIC;
    AIN0 : out STD_LOGIC_VECTOR(15 DOWNTO 0);
    AIN1 : out STD_LOGIC_VECTOR(15 DOWNTO 0);
    AIN2 : out STD_LOGIC_VECTOR(15 DOWNTO 0);
    AIN3 : out STD_LOGIC_VECTOR(15 DOWNTO 0);
    AIN4 : out STD_LOGIC_VECTOR(15 DOWNTO 0);
    AIN5 : out STD_LOGIC_VECTOR(15 DOWNTO 0);
    AIN6 : out STD_LOGIC_VECTOR(15 DOWNTO 0);
    AIN7 : out STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END i2c_top;

ARCHITECTURE behavior OF i2c_top IS
  constant OP_SIN_REG_RD : std_logic_vector(7 downto 0) := x"10";                                                                                                     
  constant OP_SIN_REG_WR : std_logic_vector(7 downto 0) := x"08";                                                                                                    
  constant OP_CON_REG_RD : std_logic_vector(7 downto 0) := x"30";                              
  constant OP_CON_REG_WR : std_logic_vector(7 downto 0) := x"28";   
  CONSTANT OSR_CFG : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"03"; 
  CONSTANT OSR_CFG_DATA : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"07"; 
  CONSTANT CHANNEL_SEL : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"11";
  SIGNAL ena         : STD_LOGIC := '0';
  SIGNAL rw          : STD_LOGIC := '0';
  SIGNAL data_wr     : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL data_rd     : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL busy_bus        : STD_LOGIC;
  type t_data is array (0 to 7) of std_logic_vector(15 downto 0);
  signal ADC_data  : t_data;
  TYPE machine IS (
  S_IDLE,
  S_SET_REQ,
  S_CONFIG_ADC,
  S_DATA_REQ,
  S_DLY,
  S_DATA_READ,
  S_SET_RD
	);
  SIGNAL delay_cnt : INTEGER range 0 to 100000 := 0 ;
  SIGNAL state         : machine;                        --state machine
  SIGNAL next_state         : machine;         
  SIGNAL read_buffer : STD_LOGIC_VECTOR(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL byte_cnt : INTEGER range 0 to 15 := 0 ;
  SIGNAL reg_cnt : INTEGER range 0 to 9 := 0 ;
  SIGNAL rd_cnt : INTEGER range 0 to 9 := 0 ;
  SIGNAL rd_ch : INTEGER range 0 to 7 := 0 ;
  SIGNAL busy_f : std_LOGIC := '0';

  SIGNAL data_wr_dly : STD_LOGIC_VECTOR(7 DOWNTO 0) :=x"08"; 
  SIGNAL wr_cnt : INTEGER range 0 to 9 := 0 ;
  COMPONENT i2c_master
    GENERIC (
      input_clk : INTEGER := 50_000_000;
      bus_clk   : INTEGER := 400_000
    );
    PORT (
      clk       : IN     STD_LOGIC;
      reset_n   : IN     STD_LOGIC;
      ena       : IN     STD_LOGIC;
      rw        : IN     STD_LOGIC;
      addr      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0);
      data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0);
      data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0);
      busy      : OUT    STD_LOGIC;
      ack_error : OUT    STD_LOGIC;
      scl       : INOUT  STD_LOGIC;
      sda       : INOUT  STD_LOGIC
    );
  END COMPONENT;

BEGIN
  i2c_inst : i2c_master
    generic map (
      input_clk => 100_000_000,
      bus_clk => 100_000
    )
    PORT MAP (
      clk       => clk,
      reset_n   => reset_n,
      ena       => ena,
      rw        => rw,
      addr      => DEV_ID,
      data_wr   => data_wr_dly,
      data_rd   => data_rd,
      busy      => busy_bus,
      ack_error => OPEN,
      scl       => scl,
      sda       => sda
    );


    AIN0(11 downto 0) <= ADC_data(0)(15 downto 4);
    AIN1(11 downto 0) <= ADC_data(1)(15 downto 4);
    AIN2(11 downto 0) <= ADC_data(2)(15 downto 4);
    AIN3(11 downto 0) <= ADC_data(3)(15 downto 4);
    AIN4(11 downto 0) <= ADC_data(4)(15 downto 4);
    AIN5(11 downto 0) <= ADC_data(5)(15 downto 4);
    AIN6(11 downto 0) <= ADC_data(6)(15 downto 4);
    AIN7(11 downto 0) <= ADC_data(7)(15 downto 4);
  PROCESS (clk, reset_n)
  BEGIN
    IF reset_n = '0' THEN
      ena <= '0';
      rw <= '0';
      state <= S_IDLE;
      byte_cnt <= 0;
      delay_cnt <= 0;
      rd_cnt <= 0;
      reg_cnt <= 0;
      wr_cnt <= 0;
      ADC_data <= (others => (others =>'0'));
    ELSIF rising_edge(clk) THEN   
    busy_f  <= busy_bus;                       
		CASE state IS
      WHEN S_IDLE =>
        
        ena <= '0';
        wr_cnt <= 0;
        rw <= '0';
        BUSY <= '0';
        if START = '1' then
          BUSY <= '1';
          state <= S_CONFIG_ADC;
        end if;
        byte_cnt <= 0;
        reg_cnt <= 0;
        data_wr_dly <= (others =>'0');
      WHEN S_CONFIG_ADC =>
        ena <= '1';
        data_wr_dly <= data_wr;
        if busy_bus = '0' and busy_f = '1' then 
          reg_cnt <= reg_cnt +1;
          if reg_cnt = 2 or reg_cnt = 5  then
            state <= S_DLY;
            ena <= '0';
            next_state <= S_CONFIG_ADC;
          elsif reg_cnt = 8 then
            state <= S_DLY;
            ena <= '0';
            next_state <= S_DATA_READ;
          else 
            null;
          end if;
        end if;
      WHEN S_DATA_READ =>
        ena <= '1';
        rw <= '1';
        if busy_bus = '0' and busy_f = '1' then 
          rd_cnt <= rd_cnt +1;
          -- state <= S_DLY;
        end if;
        if rd_cnt = 1 then
          ena <= '0';
          state <= S_DLY;
          ADC_data(rd_ch)(15 downto 8) <= data_rd;
          if rd_ch = 7 then
            BUSY <= '0';
            rd_ch <= 0;
            data_wr_dly <= OP_SIN_REG_WR;
            next_state <= S_IDLE;
          else
            rd_ch <= rd_ch +1;
            data_wr_dly <= OP_SIN_REG_WR;
            next_state <= S_SET_RD;
          end if; 
          
          rw <= '0';
          rd_cnt <= 0;
          else
            null;
        end if;
        
      WHEN S_SET_RD =>
      rw <= '0';
      ena <= '1';
      if busy_bus = '0' and busy_f = '1' then 
          wr_cnt <= wr_cnt +1;
          case wr_cnt is
            when 0 =>
              data_wr_dly <= CHANNEL_SEL;
            when 1 =>
              data_wr_dly <= std_logic_vector(to_unsigned(rd_ch, data_wr_dly'length));
            when 2 =>
              state <= S_DLY;
              next_state <= S_DATA_READ;
              ena <= '0';
              wr_cnt <= 0;
            when others =>
              null;
            end case;
      end if;


      WHEN S_DLY =>
        if delay_cnt = 99999 then
          delay_cnt <= 0;
          if next_state = S_SET_RD then
            ADC_data(rd_ch)(7 downto 0) <= data_rd;
          end if;
          state <= next_state;
        else
          delay_cnt <= delay_cnt +1;
        end if;
      WHEN others =>
        null;  
      END CASE;
    END IF;
  END PROCESS;    

  

  PROCESS (clk)
  BEGIN
  IF rising_edge(clk) THEN 
  case reg_cnt is
    when 0 =>
    data_wr <= OP_SIN_REG_WR;
    when 1 =>
      data_wr <= CHANNEL_SEL;
    when 2 =>
      data_wr <= x"02";
    when 3 =>
      data_wr <= OP_SIN_REG_WR;
    when 4 =>
      data_wr <= OSR_CFG;
    when 5 =>
      data_wr <= OSR_CFG_DATA;
    when 6 =>
      data_wr <= OP_SIN_REG_WR;
    when 7 =>
      data_wr <= CHANNEL_SEL;
    when 8 =>
      data_wr <= (others => '0');
    when others =>
      null;
  end case;
  END IF;
  END PROCESS;
END behavior;