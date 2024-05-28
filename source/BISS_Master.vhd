LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

ENTITY BISS_Master IS
  GENERIC(
    input_clk : INTEGER := 100_000_000; --input clock speed from user logic in Hz
    bus_clk   : INTEGER := 1_000_000
  );
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    START     : IN     STD_LOGIC;   
    POS       : OUT    STD_LOGIC_VECTOR(25 DOWNTO 0);
    ERR       : OUT    STD_LOGIC;
    WARN      : OUT    STD_LOGIC;
    CRC_ERR   : OUT    STD_LOGIC;
    RDY       : OUT    STD_LOGIC;
    BUSY      : OUT    STD_LOGIC;
    MCLK      : OUT    STD_LOGIC;                    --serial data output of i2c bus
    SLO       : IN     STD_LOGIC                     --serial clock output of i2c bus
  );
END BISS_Master;

ARCHITECTURE logic OF BISS_Master IS

  TYPE machine IS (
    S_IDLE,
    S_CLK0,
    S_CLK1,
    S_START_MA,
    S_WAIT_ACK,
    S_START,
    S_CDS,
    S_GET_POS,
    S_GET_ERR,
    S_GET_WARN,
    S_CRC,
    S_RESTART
  );
  SIGNAL prev_state         : machine;                        --state machine  
  SIGNAL state         : machine;                        --state machine
  SIGNAL count         : INTEGER := 0;
  SIGNAL pos_cnt       : INTEGER RANGE 0 TO 31 := 0;
  SIGNAL tmp_clk       : STD_LOGIC := '0';
  SIGNAL CRC           : STD_LOGIC_VECTOR(5 DOWNTO 0);
  SIGNAL calculated_crc: STD_LOGIC_VECTOR(5 DOWNTO 0) := (others => '0');
  SIGNAL crc_check     : STD_LOGIC := '0';
  SIGNAL START_sync : STD_LOGIC := '0';
  SIGNAL START_sync_cnt : INTEGER := 0;
BEGIN

process(clk, reset_n)
begin
  if reset_n = '0' then
    tmp_clk <= '0';
    count <= 0;
  elsif rising_edge(clk) then
    if count >= (input_clk / bus_clk) / 2 - 1 then
      tmp_clk <= not tmp_clk;
      count <= 0;
    else
      count <= count + 1;
    end if;
  end if;
end process;

process(state)
begin
  CASE state IS
    WHEN S_RESTART => 
      MCLK <= '1';
    WHEN S_IDLE => 
      MCLK <= '1';
    WHEN S_CLK1 => 
      if prev_state = S_CLK1 then
        MCLK <= '1';
      else
        MCLK <= tmp_clk;
      end if;
    WHEN others =>
      MCLK <= tmp_clk;  
  END CASE;
end process;

process(clk, reset_n)
begin
  if reset_n = '0' then
    START_sync <=  '0';
	START_sync_cnt <= 0;
  elsif rising_edge(clk) then
	if START = '1' then
		START_sync <= '1';
	end if;
	if START_sync = '1' then
		if START_sync_cnt >= (input_clk / bus_clk)  - 1 then
			START_sync <= START;
			START_sync_cnt <= 0;
		else
			START_sync_cnt <= START_sync_cnt + 1;
		end if;
	end if;

  end if;
end process;

-- CRC calculation process
process(clk, reset_n)
begin
  if reset_n = '0' then
    calculated_crc <= (others => '0');
  elsif falling_edge(tmp_clk) then
    if state = S_GET_POS or state = S_GET_ERR or state = S_GET_WARN then
      if calculated_crc(5) = '1' then
        calculated_crc <= (calculated_crc(4 downto 0) & SLO) xor "100011";
      else
        calculated_crc <= (calculated_crc(4 downto 0) & SLO);
      end if;
    end if;
  end if;
end process;

process(clk, reset_n)
begin
  if reset_n = '0' then                 --reset asserted
    state <= S_IDLE;                      --return to initial state
    pos_cnt <= 0;
    RDY <= '0';
    BUSY <= '0';
    POS <= (others => '0');
    ERR <= '0';
    WARN <= '0';
    CRC <= (others => '0');

    crc_check <= '0';
  elsif falling_edge(tmp_clk) then
    prev_state <= state;
    CASE state IS
      WHEN S_IDLE =>
        state <= S_IDLE;
        BUSY <= '0';
        if START_sync = '1' then
          state <= S_CLK0;
        end if;
      WHEN S_CLK0 =>  
        state <= S_CLK1;
      WHEN S_CLK1 =>  
        state <= S_START_MA;
      WHEN S_START_MA =>  
        state <= S_START_MA;
        if SLO = '0' then
          BUSY <= '1';
          state <= S_WAIT_ACK;
        end if;
        
      WHEN S_WAIT_ACK => 
        state <= S_WAIT_ACK;
        if SLO = '1' then
          state <= S_START;
        end if;
        
      WHEN S_START => 
        state <= S_START;
        if SLO = '0' then
          state <= S_CDS;
        end if;
        
      WHEN S_CDS => 
        if SLO = '0' then
          state <= S_GET_POS;
        end if;
        
      WHEN S_GET_POS => 
        pos_cnt <= pos_cnt + 1;
        POS(25 - pos_cnt) <= SLO;
        state <= S_GET_POS;
        if pos_cnt = 25 then
          POS(25 - pos_cnt) <= SLO;
          pos_cnt <= 0;
          state <= S_GET_ERR;
        end if;
        
      WHEN S_GET_ERR => 
        ERR <= SLO;
        state <= S_GET_WARN;
        
      WHEN S_GET_WARN => 
        WARN <= SLO;
        state <= S_CRC;
        
      WHEN S_CRC => 
        state <= S_CRC;
        pos_cnt <= pos_cnt + 1;
        CRC(5 - pos_cnt) <= SLO;
        if pos_cnt = 5 then
          CRC(5 - pos_cnt) <= SLO;
          pos_cnt <= 0;
          RDY <= '1';
          BUSY <= '0';
          state <= S_RESTART;
          if calculated_crc = CRC then
            crc_check <= '0';  -- CRC check passed
          else
            crc_check <= '1';  -- CRC check failed
          end if;
        end if;
        
      WHEN S_RESTART => 
    RDY <= '0';
		WARN <= '0';
		ERR <= '0';
        state <= S_RESTART;
        if SLO = '0' then
          state <= S_IDLE;
        end if;
        
      WHEN others =>
        null;
    END CASE;
  end if;
end process;

CRC_ERR <= crc_check;

END logic;