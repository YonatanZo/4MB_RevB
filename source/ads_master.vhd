
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity ads_master is
  generic
  (
    input_clk : integer                      := 50_000_000; --input clock speed from user logic in Hz
    addr      : std_logic_vector(6 downto 0) := "0010000";
    bus_clk   : integer                      := 400_000); --speed the i2c bus (scl) will run at in Hz
  port
  (
    clk       : in std_logic; --system clock
    reset_n   : in std_logic; --active low reset
    ena       : in std_logic; --latch in command
    rw        : in std_logic; --'0' is write, '1' is read
    burst     : in std_logic; --'1' burst mode enable
    burst_len : in std_logic_vector(7 downto 0);
    data_wr   : in std_logic_vector(7 downto 0);  --data to write to slave
    reg_adrr  : in std_logic_vector(7 downto 0);  --address to write/read from/to slave
    busy      : out std_logic;                    --indicates transaction in progress
    rd_rdy    : out std_logic;                    --indicates burst read date is ready
    data_rd   : out std_logic_vector(7 downto 0); --data read from slave
    debug     : out std_logic_vector(7 downto 0);
    ack_error : buffer std_logic; --flag if improper acknowledge from slave
    sda       : inout std_logic;  --serial data output of i2c bus
    scl       : inout std_logic); --serial clock output of i2c bus
end ads_master;

architecture logic of ads_master is
  constant divider       : integer                      := (input_clk/bus_clk)/4;                                                                                                --number of clocks in 1/4 cycle of scl
  constant OP_SIN_REG_RD : std_logic_vector(7 downto 0) := x"10";                                                                                                                --Single register read
  constant OP_SIN_REG_WR : std_logic_vector(7 downto 0) := x"08";                                                                                                                --Single register write
  constant OP_CON_REG_RD : std_logic_vector(7 downto 0) := x"30";                                                                                                                --Reading a continuous block of registers
  constant OP_CON_REG_WR : std_logic_vector(7 downto 0) := x"28";                                                                                                                --Writing a continuous block of registers
  type machine is(s_ready, s_start, s_command, s_slv_ack1, s_op, s_slv_ack_op, s_wr_reg, s_slv_ack_reg, s_wr, s_rd, s_slv_ack2, s_slv_ack_rd, s_mstr_ack, s_stop, s_rd_command); --needed states
  signal state         : machine;                                                                                                                                                --state machine
  signal data_clk      : std_logic;                                                                                                                                              --data clock for sda
  signal data_clk_prev : std_logic;                                                                                                                                              --data clock during previous system clock
  signal scl_clk       : std_logic;                                                                                                                                              --constantly running internal scl
  signal scl_ena       : std_logic := '0';                                                                                                                                       --enables internal scl to output
  signal sda_int       : std_logic := '1';                                                                                                                                       --internal sda
  signal sda_ena_n     : std_logic;                                                                                                                                              --enables internal sda to output
  signal rd_op         : std_logic := '0';
  signal addr_rw       : std_logic_vector(7 downto 0); --latched in address and read/write
  signal data_tx       : std_logic_vector(7 downto 0); --latched in data to write to slave
  signal op_tx         : std_logic_vector(7 downto 0); --latched in data to write to slave
  signal data_rx       : std_logic_vector(7 downto 0); --data received from slave
  signal bit_cnt       : integer range 0 to 7   := 7;  --tracks bit number in transaction
  signal regs_cnt      : integer range 0 to 255 := 0;
  signal stretch       : std_logic              := '0'; --identifies if slave is stretching scl
  signal debug_SR      : std_logic_vector(7 downto 0);
begin
  debug <= debug_SR;
  --generate the timing for the bus clock (scl_clk) and the data clock (data_clk)
  process (clk, reset_n)
    variable count : integer range 0 to divider * 4; --timing for clock generation
  begin
    if (reset_n = '0') then --reset asserted
      stretch <= '0';
      count := 0;
    elsif (clk'EVENT and clk = '1') then
      data_clk_prev <= data_clk;        --store previous value of data clock
      if (count = divider * 4 - 1) then --end of timing cycle
        count := 0;                       --reset timer
      elsif (stretch = '0') then        --clock stretching from slave not detected
        count := count + 1;               --continue clock generation timing
      end if;
      case count is
        when 0 to divider - 1 => --first 1/4 cycle of clocking
          scl_clk  <= '0';
          data_clk <= '0';
        when divider to divider * 2 - 1 => --second 1/4 cycle of clocking
          scl_clk  <= '0';
          data_clk <= '1';
        when divider * 2 to divider * 3 - 1 => --third 1/4 cycle of clocking
          scl_clk <= '1';                        --release scl
          if (scl = '0') then                    --detect if slave is stretching clock
            stretch <= '1';
          else
            stretch <= '0';
          end if;
          data_clk <= '1';
        when others => --last 1/4 cycle of clocking
          scl_clk  <= '1';
          data_clk <= '0';
      end case;
    end if;
  end process;
  --busy moore
  process (clk, reset_n)
  begin
    if (reset_n = '0') then --reset asserted
      busy <= '1';            --indicate not available
    elsif (rising_edge(clk)) then
      case state is
        when s_ready =>
          busy <= '0'; --unflag busy
        when s_start =>
          busy <= '1'; --resume busy if continuous mode
        when s_command =>
          busy <= '1';
        when s_rd_command =>
          busy <= '1';
        when s_slv_ack_rd =>
          busy <= '1';
        when s_slv_ack1 => --slave acknowledge bit (command) 
          busy <= '1';
        when s_op =>
          busy <= '1';
        when s_slv_ack_op => --slave acknowledge bit (write)
          busy <= '1';
        when s_wr_reg =>      --write byte of transaction
          busy <= '1';          --resume busy if continuous mode
        when s_slv_ack_reg => --slave acknowledge bit (write)
          busy <= '1';          --continue is accepted     
        when s_wr =>          --write byte of transaction
          busy <= '1';          --resume busy if continuous mode
        when s_rd =>          --read byte of transaction
          busy <= '1';          --resume busy if continuous mode  
        when s_slv_ack2 =>    --slave acknowledge bit (write)
          busy <= '1';
        when s_mstr_ack => --master acknowledge bit after a read
          busy <= '1';
        when s_stop => --stop bit of transaction
          busy <= '1';
      end case;
    end if;
  end process;
  --state machine and writing to sda during scl low (data_clk rising edge)
  process (clk, reset_n)
  begin
    if (reset_n = '0') then --reset asserted
      state <= s_ready;       --return to initial state

      scl_ena   <= '0';        --sets scl high impedance
      sda_int   <= '1';        --sets sda high impedance
      ack_error <= '0';        --clear acknowledge error flag
      bit_cnt   <= 7;          --restarts data bit counter
      data_rd   <= "00000000"; --clear data read port
      op_tx     <= (others => '0');
      regs_cnt  <= 0;
    elsif (rising_edge(clk)) then
      if (data_clk = '1' and data_clk_prev = '0') then --data clock rising edge
        case state is

            --idle state
          when s_ready =>
            if (ena = '1') then    --transaction requested
              addr_rw <= addr & '0'; --collect requested slave address and command,in this device alwayes staert with write(low)
              data_tx <= data_wr;    --collect requested data to write
              if (rw = '0' and burst = '0') then
                op_tx <= OP_SIN_REG_WR;
              elsif (rw = '0' and burst = '1') then
                op_tx <= OP_CON_REG_WR;
              elsif (rw = '1' and burst = '0') then
                op_tx <= OP_SIN_REG_RD;
              elsif (rw = '1' and burst = '1') then
                op_tx <= OP_CON_REG_RD;
              end if;
              state <= s_start; --go to start bit

            else              --remain idle
              state <= s_ready; --remain idle
            end if;

            --start bit of transaction
            --start condition 
          when s_start =>

            if rd_op = '1' then
              rd_op   <= '0';
              addr_rw <= addr & '1';
              state   <= s_rd_command; --go to command
            else
              sda_int <= addr_rw(bit_cnt); --set first address bit to bus
              state   <= s_command;        --go to command
            end if;

            --address and command byte of transaction
            --writing device ID and write bit
          when s_command =>
            if (bit_cnt = 0) then            --command transmit finished
              sda_int <= '1';                  --release sda for slave acknowledge
              bit_cnt <= 7;                    --reset bit counter for "byte" states
              state   <= s_slv_ack1;           --go to slave acknowledge (command)
            else                             --next clock cycle of command state
              bit_cnt <= bit_cnt - 1;          --keep track of transaction bits
              sda_int <= addr_rw(bit_cnt - 1); --write address/command bit to bus
              state   <= s_command;            --continue with command
            end if;

          when s_rd_command =>
            if (bit_cnt = 0) then            --command transmit finished
              sda_int <= '1';                  --release sda for slave acknowledge
              bit_cnt <= 7;                    --reset bit counter for "byte" states
              state   <= s_slv_ack_rd;         --go to slave acknowledge (command)
            else                             --next clock cycle of command state
              bit_cnt <= bit_cnt - 1;          --keep track of transaction bits
              sda_int <= addr_rw(bit_cnt - 1); --write address/command bit to bus
              state   <= s_rd_command;         --continue with command
            end if;
          when s_slv_ack_rd =>

            sda_int <= '1'; --release sda from incoming data
            if burst = '1' then
              regs_cnt <= to_integer(unsigned(burst_len));
            else
              regs_cnt <= 0;
            end if;
            state <= s_rd; --go to read byte
            --get slave ACK after writing device ID     
          when s_slv_ack1 => --slave acknowledge bit (command) 
            sda_int <= op_tx(bit_cnt);
            state   <= s_op;
            --writing OP code                 
          when s_op =>

            if (bit_cnt = 0) then
              sda_int <= '1';
              bit_cnt <= 7;
              state   <= s_slv_ack_op;
            else
              bit_cnt <= bit_cnt - 1;
              sda_int <= op_tx(bit_cnt - 1);
              state   <= s_op;
            end if;
            --get slave ACK after writing OP code 
          when s_slv_ack_op => --slave acknowledge bit (write)

            sda_int <= reg_adrr(bit_cnt); --write first bit of data
            state   <= s_wr_reg;          --go to write byte
            --writing register address   
          when s_wr_reg => --write byte of transaction

            if (bit_cnt = 0) then             --write byte transmit finished
              sda_int <= '1';                   --release sda for slave acknowledge
              bit_cnt <= 7;                     --reset bit counter for "byte" states
              state   <= s_slv_ack_reg;         --go to slave acknowledge (write)
            else                              --next clock cycle of write state
              bit_cnt <= bit_cnt - 1;           --keep track of transaction bits
              sda_int <= reg_adrr(bit_cnt - 1); --write next bit to bus
              state   <= s_wr_reg;              --continue writing
            end if;
            --get slave ACKafter writing reg address  
          when s_slv_ack_reg => --slave acknowledge bit (write)

            if (rw = '0') then --start writing oparation 
              data_tx <= data_wr;
              sda_int <= data_wr(bit_cnt); --write first bit of data
              rd_op   <= '0';
              state   <= s_wr; --go to write byte 
            else
              rd_op <= '1';
              state <= s_stop;
              --add P/Sr state -->Start state --> read /reas seq 
            end if;

          when s_wr => --write byte of transaction

            if (bit_cnt = 0) then --write byte transmit finished
              sda_int <= '1';       --release sda for slave acknowledge
              bit_cnt <= 7;         --reset bit counter for "byte" states
              if burst = '1' then
                regs_cnt <= regs_cnt - 1;
              end if;
              state <= s_slv_ack2;             --go to slave acknowledge (write)
            else                             --next clock cycle of write state
              bit_cnt <= bit_cnt - 1;          --keep track of transaction bits
              sda_int <= data_tx(bit_cnt - 1); --write next bit to bus
              if (burst = '1') then
                regs_cnt <= to_integer(unsigned(burst_len));
              end if;
              state <= s_wr; --continue writing
            end if;

          when s_rd => --read byte of transaction

            if (bit_cnt = 0) then --read byte receive finished
              bit_cnt  <= 7;        --reset bit counter for "byte" states
              data_rd  <= data_rx;  --output received data
              regs_cnt <= regs_cnt - 1;
              state    <= s_mstr_ack; --go to master acknowledge
              rd_rdy   <= '1';
            else                    --next clock cycle of read state
              bit_cnt <= bit_cnt - 1; --keep track of transaction bits
              state   <= s_rd;        --continue reading
            end if;

          when s_slv_ack2 => --slave acknowledge bit (write)
            if (burst = '1' and regs_cnt /= 0 and rw = '0') then
              data_tx <= data_wr;
              sda_int <= data_wr(bit_cnt); --write first bit of data
              state   <= s_wr;
            elsif (rw = '0') then
              state <= s_stop;
            end if;

          when s_mstr_ack => --master acknowledge bit after a read
            rd_rdy <= '0';
            if (regs_cnt /= 0) then --continue transaction
              sda_int <= '1';         --release sda from incoming data
              state   <= s_rd;        --go to read byte

            else             --complete transaction
              state <= s_stop; --go to stop bit
            end if;

          when s_stop => --stop bit of transaction
            if rd_op = '1' then
              state <= s_start;
            else
              state <= s_ready; --go to idle state
            end if;
        end case;

      elsif (data_clk = '0' and data_clk_prev = '1') then --data clock falling edge
        case state is
            --starting new transaction
          when s_start =>
            if (scl_ena = '0') then
              scl_ena   <= '1'; --enable scl output
              ack_error <= '0'; --reset acknowledge error output
            end if;
            --receiving slave acknowledge (command)
          when s_slv_ack1 =>
            if (sda /= '0' or ack_error = '1') then --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                       --set error output if no-acknowledge
            end if;
            --receiving slave data
          when s_rd =>
            data_rx(bit_cnt) <= sda; --receive current slave data bit
            --receiving slave acknowledge (write)
          when s_slv_ack2 =>
            if (sda /= '0' or ack_error = '1') then --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                       --set error output if no-acknowledge
            end if;
            --disable scl
          when s_stop =>
            scl_ena <= '0';
          when s_slv_ack_op =>
            if (sda /= '0' or ack_error = '1') then --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                       --set error output if no-acknowledge
            end if;
          when s_slv_ack_reg =>
            if (sda /= '0' or ack_error = '1') then --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                       --set error output if no-acknowledge
            end if;
          when s_slv_ack_rd =>
            if (sda /= '0' or ack_error = '1') then --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                       --set error output if no-acknowledge
            end if;
          when others =>
            null;
        end case;
      end if;
    end if;
  end process;

  --set sda output
  with state select
    sda_ena_n <= data_clk_prev when s_start, --generate start condition
    not data_clk_prev when s_stop,           --generate stop condition
    sda_int when others;                     --set to internal sda signal    

  --set scl and sda outputs
  scl <= '0' when (scl_ena = '1' and scl_clk = '0') else
    'Z';
  sda <= '0' when sda_ena_n = '0' else
    'Z';
  process (clk)
  begin
    if rising_edge(scl) then
      debug_SR <= debug_SR(6 downto 0) & sda;
    end if;
  end process;
end logic;