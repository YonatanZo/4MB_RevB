
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_arith.all;

ENTITY spi_if IS

  PORT(
    clk_100m         : IN     STD_LOGIC;  --spi clk from master
    rst_n_syn      : IN     STD_LOGIC;  --active low reset
    --SPI INTERFACE
    sclk         : IN     STD_LOGIC;  --spi clk from master
    cs_n         : IN     STD_LOGIC;  --active low slave select
    mosi         : IN     STD_LOGIC;  --master out, slave in
    miso_t       : OUT     STD_LOGIC;  --'1' while busy = '0' moves data to the rx_data output
    --INTERNAL INTERFACE
    data_miso   : IN     STD_LOGIC_VECTOR(31 DOWNTO 0); --data for transmission to SPI master
    data_mosi : OUT     STD_LOGIC_VECTOR(31 DOWNTO 0);  --received data from SPI master
    data_mosi_rdy : OUT     STD_LOGIC;                  --when 1, received data are valid
    addr  : OUT     STD_LOGIC_VECTOR(15 DOWNTO 0):=(others =>'0');
    addr_rdy   : OUT     STD_LOGIC;  
    data_miso_rdy : OUT     STD_LOGIC); 
END spi_if;

ARCHITECTURE logic OF spi_if IS
constant COM_LEN : integer := 4;
constant WRITE_COM : std_logic_vector(COM_LEN-1 downto 0) := x"6";
constant READ_COM  : std_logic_vector(COM_LEN-1 downto 0) := x"9";
constant ADDR_LEN  : integer := 12;
constant DATA_LEN  : integer := 32;
constant CRC_LEN  : integer := 8;
signal data_mosi_rdy_f            : std_logic;

signal cmd        : std_logic_vector(COM_LEN-1 downto 0); 
signal addr_rdy_f          : std_logic;
signal data_miso_rdy_f : std_logic;
signal cmd_rdy           : std_logic;
signal MOSI_reg        : std_logic_vector(55 downto 0); 
signal data_miso_cnt : integer range 0 to 32;
signal clk_fall_cnt : integer range 0 to 127;
signal clk_rising_cnt : integer range 0 to 127:= 0;
signal clk_rising_cnt_f           : integer range 0 to 127:= 0;
signal clk_rising_cnt_ff          : integer range 0 to 127:= 0;
type state_type is (S_IDLE, S_CMD, S_ADDR, S_MOSI_DATA,S_MISO_DATA,S_CRC_CHECK,S_CRC_TX,S_ERR);
signal state : state_type;
signal addr_f   :    STD_LOGIC_VECTOR(ADDR_LEN-1 DOWNTO 0):=(others =>'0');
signal data_mosi_f  :    STD_LOGIC_VECTOR(DATA_LEN-1 DOWNTO 0):=(others =>'0');
SIGNAL crcOut :  std_logic_vector(5 downto 0);
SIGNAL crcOut_MOSI :  std_logic_vector(5 downto 0);
SIGNAL crcIn :  std_logic_vector(CRC_LEN-1 downto 0);
SIGNAL crc_bit : std_logic;
SIGNAL miso_t_f : std_logic;
SIGNAL crc_idx : integer range 0 to CRC_LEN-1:= 0;
BEGIN
miso_t <= miso_t_f;
addr(ADDR_LEN-1 DOWNTO 0) <= addr_f;
addr_rdy <= addr_rdy_f;
data_miso_rdy <= data_miso_rdy_f;
data_mosi_rdy <= data_mosi_rdy_f;

process (sclk, cs_n)
begin
  if cs_n = '1' then
    state <=S_IDLE;
    clk_rising_cnt <= 0;
    cmd <= (others => '0');
    addr_f <= (others => '0');
    data_mosi_f <= (others => '0');
    miso_t_f <= 'Z';
    crcOut_MOSI <= (others => '0');
  elsif rising_edge(sclk) then
    case state is
      when S_IDLE =>
        clk_rising_cnt <= 0;
        cmd <= (others => '0');
        addr_f <= (others => '0');
        data_mosi_f <= (others => '0');
        cmd <= cmd(cmd'HIGH-1 downto 0) & mosi;
        state <=S_CMD;
        crc_idx <= 0;
      when S_CMD =>
        clk_rising_cnt <= clk_rising_cnt+1;
        if clk_rising_cnt = COM_LEN-1 then
          addr_f <= addr_f(addr_f'HIGH-1 downto 0) & mosi;
          state <=S_ADDR;
        else 
          cmd <= cmd(cmd'HIGH-1 downto 0) & mosi;
        end if;
      when S_ADDR =>
        clk_rising_cnt <= clk_rising_cnt+1;
        if clk_rising_cnt = ADDR_LEN+COM_LEN-1 then
          if cmd = WRITE_COM then
            data_mosi_f <= data_mosi_f(data_mosi_f'HIGH-1 downto 0) & mosi;
            state <=S_MOSI_DATA;
          elsif cmd = READ_COM then
            miso_t_f <= data_miso(ADDR_LEN+COM_LEN-1-clk_rising_cnt-2);
            state <=S_MISO_DATA;
          else 
          state <=S_ERR;
          end if;
        else
          addr_f <= addr_f(addr_f'HIGH-1 downto 0) & mosi;
        end if;
      when S_MOSI_DATA =>
        clk_rising_cnt <= clk_rising_cnt+1;
        data_mosi_f <= data_mosi_f(data_mosi_f'HIGH-1 downto 0) & mosi;
        if clk_rising_cnt = DATA_LEN+ADDR_LEN+COM_LEN-1 then
          crcIn <= crcIn(crcIn'HIGH-1 downto 0)& mosi;
          crcOut_MOSI <= not CrcOut;
          state  <=S_CRC_CHECK;
        end if;
      when S_MISO_DATA =>
      clk_rising_cnt <= clk_rising_cnt+1;
      miso_t_f <= data_miso(ADDR_LEN+COM_LEN-1-clk_rising_cnt-2);
      if clk_rising_cnt = DATA_LEN+ADDR_LEN+COM_LEN-1 then
        state <=S_CRC_TX;
      end if;
      when S_CRC_CHECK =>
        if crc_idx = CRC_LEN-1 then
          crc_idx <= 0;
          if crcIn(5 downto 0) = crcOut_MOSI then
            state <= S_IDLE;
          else
            state <= S_ERR;
          end if;
        else
          crc_idx <= crc_idx +1;
        end if;
        crcIn <= crcIn(crcIn'HIGH-1 downto 0)& mosi;
      when S_CRC_TX =>
        if crc_idx = CRC_LEN-1 then
          crc_idx <= 0;
          state <= S_IDLE;
        else
          crc_idx <= crc_idx +1;
        end if;
        miso_t_f <= crcOut_MOSI(crc_idx);
      when S_ERR =>
        state <=S_ERR;
      when others =>
        null;
    end case;
  end if;
end process;

  process (clk_100m, rst_n_syn)
  begin
    if rst_n_syn = '0' then
      data_mosi_rdy_f <= '0';
      addr_rdy_f <= '0';
      clk_rising_cnt_f <= 0;
      clk_rising_cnt_ff <= 0;
      data_miso_rdy_f <= '0';
    elsif rising_edge(clk_100m) then
      clk_rising_cnt_f <= clk_rising_cnt;
      clk_rising_cnt_ff <= clk_rising_cnt_f;
      case clk_rising_cnt_ff is
        when ADDR_LEN+COM_LEN-1  =>
          addr_rdy_f <= '1';
        when DATA_LEN+ADDR_LEN+COM_LEN-1 =>
        if state = S_MOSI_DATA then
          data_mosi <= data_mosi_f;
          data_mosi_rdy_f <= '1';
        end if;
        if state = S_MISO_DATA then
          data_miso_rdy_f <= '1';
        end if;
        -- when DATA_LEN+ADDR_LEN+COM_LEN-1+6 =>
        --   if crcOut_not /= crcIn then
        --     CRC_ERR <= '1';
        --   end if;
        when others =>
          data_mosi_rdy_f <= '0';
          addr_rdy_f <= '0';
          data_miso_rdy_f <= '0';
      end case;
    end if;
    end process;
 
    process(sclk, cs_n)
    begin
      if cs_n = '1' then
        crcOut <= (others => '0');
        crc_bit <= '0';
      elsif rising_edge(sclk) then
        if state = S_MISO_DATA then
          crc_bit <= miso_t_f;
        else 
          crc_bit <= mosi;
        end if;

          crcOut(5) <= crcOut(4);
          crcOut(4) <= crcOut(3);
          crcOut(3) <= crcOut(2);
          crcOut(2) <= crcOut(1);
          crcOut(1) <= (crcOut(0) XOR crc_bit XOR crcOut(5));
          crcOut(0) <= (crc_bit XOR crcOut(5));
      end if;
      end process;

END logic;
