
LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;
USE ieee.numeric_std.all;
ENTITY ads_master IS
  GENERIC(
    input_clk : INTEGER := 50_000_000; --input clock speed from user logic in Hz
    addr : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0010000";
    bus_clk   : INTEGER := 400_000);   --speed the i2c bus (scl) will run at in Hz
  PORT(
    clk       : IN     STD_LOGIC;                    --system clock
    reset_n   : IN     STD_LOGIC;                    --active low reset
    ena       : IN     STD_LOGIC;                    --latch in command
    rw        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    burst     : IN     STD_LOGIC;                    --'1' burst mode enable
    burst_len : IN     STD_LOGIC_VECTOR(7 DOWNTO 0);
    data_wr   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    reg_adrr  : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --address to write/read from/to slave
    busy      : OUT    STD_LOGIC;                    --indicates transaction in progress
    rd_rdy    : OUT    STD_LOGIC;                    --indicates burst read date is ready
    data_rd   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    debug   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); 
    ack_error : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    sda       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    scl       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END ads_master;

ARCHITECTURE logic OF ads_master IS
  CONSTANT divider  :  INTEGER := (input_clk/bus_clk)/4; --number of clocks in 1/4 cycle of scl
  CONSTANT OP_SIN_REG_RD : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"10";  --Single register read
  CONSTANT OP_SIN_REG_WR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"08"; --Single register write
  CONSTANT OP_CON_REG_RD : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"30";  --Reading a continuous block of registers
  CONSTANT OP_CON_REG_WR : STD_LOGIC_VECTOR(7 DOWNTO 0) := x"28";  --Writing a continuous block of registers
  TYPE machine IS(s_ready, s_start, s_command, s_slv_ack1, s_op , s_slv_ack_op , s_wr_reg , s_slv_ack_reg , s_wr, s_rd, s_slv_ack2, s_slv_ack_rd, s_mstr_ack, s_stop ,s_rd_command); --needed states
  SIGNAL state         : machine;                        --state machine
  SIGNAL data_clk      : STD_LOGIC;                      --data clock for sda
  SIGNAL data_clk_prev : STD_LOGIC;                      --data clock during previous system clock
  SIGNAL scl_clk       : STD_LOGIC;                      --constantly running internal scl
  SIGNAL scl_ena       : STD_LOGIC := '0';               --enables internal scl to output
  SIGNAL sda_int       : STD_LOGIC := '1';               --internal sda
  SIGNAL sda_ena_n     : STD_LOGIC;                      --enables internal sda to output
  SIGNAL rd_op     : STD_LOGIC:= '0';                      
  SIGNAL addr_rw       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --latched in address and read/write
  SIGNAL data_tx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --latched in data to write to slave
  SIGNAL op_tx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --latched in data to write to slave
  SIGNAL data_rx       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --data received from slave
  SIGNAL bit_cnt       : INTEGER RANGE 0 TO 7 := 7;      --tracks bit number in transaction
  SIGNAL regs_cnt   : INTEGER RANGE 0 TO 255 := 0; 
  SIGNAL stretch       : STD_LOGIC := '0';               --identifies if slave is stretching scl
  SIGNAL debug_SR : STD_LOGIC_VECTOR(7 DOWNTO 0);
BEGIN
debug <= debug_SR;
  --generate the timing for the bus clock (scl_clk) and the data clock (data_clk)
  PROCESS(clk, reset_n)
    VARIABLE count  :  INTEGER RANGE 0 TO divider*4;  --timing for clock generation
  BEGIN
    IF(reset_n = '0') THEN                --reset asserted
      stretch <= '0';
      count := 0;
    ELSIF(clk'EVENT AND clk = '1') THEN
      data_clk_prev <= data_clk;          --store previous value of data clock
      IF(count = divider*4-1) THEN        --end of timing cycle
        count := 0;                       --reset timer
      ELSIF(stretch = '0') THEN           --clock stretching from slave not detected
        count := count + 1;               --continue clock generation timing
      END IF;
      CASE count IS
        WHEN 0 TO divider-1 =>            --first 1/4 cycle of clocking
          scl_clk <= '0'; 
          data_clk <= '0';
        WHEN divider TO divider*2-1 =>    --second 1/4 cycle of clocking
          scl_clk <= '0';
          data_clk <= '1';
        WHEN divider*2 TO divider*3-1 =>  --third 1/4 cycle of clocking
          scl_clk <= '1';                 --release scl
          IF(scl = '0') THEN              --detect if slave is stretching clock
            stretch <= '1';
          ELSE
            stretch <= '0';
          END IF;
          data_clk <= '1';
        WHEN OTHERS =>                    --last 1/4 cycle of clocking
          scl_clk <= '1';
          data_clk <= '0';
      END CASE;
    END IF;
  END PROCESS;


--busy moore
  PROCESS(clk, reset_n)
  BEGIN
    IF(reset_n = '0') THEN                 --reset asserted
      busy <= '1';                         --indicate not available
    ELSIF(rising_edge(clk)) THEN
      CASE state IS
        WHEN s_ready =>                      
          busy <= '0';                   --unflag busy
        WHEN s_start =>  
          busy <= '1';                     --resume busy if continuous mode
        WHEN s_command =>                    
          busy <= '1';
        WHEN s_rd_command =>                    
          busy <= '1';
        WHEN s_slv_ack_rd =>
          busy <= '1';
        WHEN s_slv_ack1 =>                   --slave acknowledge bit (command) 
          busy <= '1';        
        WHEN s_op =>                  
          busy <= '1';
        WHEN s_slv_ack_op =>                   --slave acknowledge bit (write)
          busy <= '1';
        WHEN s_wr_reg =>                         --write byte of transaction
          busy <= '1';                     --resume busy if continuous mode
        WHEN s_slv_ack_reg =>                   --slave acknowledge bit (write)
          busy <= '1';                   --continue is accepted     
        WHEN s_wr =>                         --write byte of transaction
          busy <= '1';                     --resume busy if continuous mode
        WHEN s_rd =>                         --read byte of transaction
          busy <= '1';                     --resume busy if continuous mode  
        WHEN s_slv_ack2 =>                   --slave acknowledge bit (write)
          busy <= '1';
        WHEN s_mstr_ack =>                   --master acknowledge bit after a read
          busy <= '1';
        WHEN s_stop =>                       --stop bit of transaction
          busy <= '1';
      END CASE;    
    end if;
  END PROCESS;  
  --state machine and writing to sda during scl low (data_clk rising edge)
  PROCESS(clk, reset_n)
  BEGIN
    IF(reset_n = '0') THEN                 --reset asserted
      state <= s_ready;                      --return to initial state

      scl_ena <= '0';                      --sets scl high impedance
      sda_int <= '1';                      --sets sda high impedance
      ack_error <= '0';                    --clear acknowledge error flag
      bit_cnt <= 7;                        --restarts data bit counter
      data_rd <= "00000000";               --clear data read port
      op_tx  <= (others => '0');
      regs_cnt <= 0;
    ELSIF(rising_edge(clk)) THEN
      IF(data_clk = '1' AND data_clk_prev = '0') THEN  --data clock rising edge
        CASE state IS
         
		 --idle state
		 WHEN s_ready =>                      
            IF(ena = '1') THEN               --transaction requested
              addr_rw <= addr & '0';          --collect requested slave address and command,in this device alwayes staert with write(low)
              data_tx <= data_wr;            --collect requested data to write
              IF    (rw = '0' and burst = '0') then
                op_tx <= OP_SIN_REG_WR;
              elsif (rw = '0' and burst = '1') then
                op_tx <= OP_CON_REG_WR;
              elsif (rw = '1' and burst = '0') then
                op_tx <= OP_SIN_REG_RD;
              elsif (rw = '1' and burst = '1') then
                op_tx <= OP_CON_REG_RD;
              END if;
              state <= s_start;                --go to start bit
            
            ELSE                             --remain idle
              state <= s_ready;                --remain idle
            END IF;
          
		  --start bit of transaction
      --start condition 
		  WHEN s_start =>  

            if rd_op = '1' then
              rd_op <= '0'; 
              addr_rw <= addr & '1'; 
              state <= s_rd_command;                --go to command
            else
              sda_int <= addr_rw(bit_cnt);     --set first address bit to bus
              state <= s_command;                --go to command
            end if;

          --address and command byte of transaction
      --writing device ID and write bit
		  WHEN s_command =>                    
            IF(bit_cnt = 0) THEN             --command transmit finished
              sda_int <= '1';                --release sda for slave acknowledge
              bit_cnt <= 7;                  --reset bit counter for "byte" states
              state <= s_slv_ack1;             --go to slave acknowledge (command)
            ELSE                             --next clock cycle of command state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              sda_int <= addr_rw(bit_cnt-1); --write address/command bit to bus
              state <= s_command;              --continue with command
            END IF;

      WHEN s_rd_command =>                    
            IF(bit_cnt = 0) THEN             --command transmit finished
              sda_int <= '1';                --release sda for slave acknowledge
              bit_cnt <= 7;                  --reset bit counter for "byte" states
              state <= s_slv_ack_rd;             --go to slave acknowledge (command)
            ELSE                             --next clock cycle of command state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              sda_int <= addr_rw(bit_cnt-1); --write address/command bit to bus
              state <= s_rd_command;              --continue with command
            END IF;
      WHEN s_slv_ack_rd =>
 
        sda_int <= '1';              --release sda from incoming data
        if burst = '1' then
          regs_cnt <= to_integer(unsigned(burst_len));
        else regs_cnt <= 0 ;
        end if;
        state <= s_rd;                 --go to read byte
      --get slave ACK after writing device ID     
		  WHEN s_slv_ack1 =>                   --slave acknowledge bit (command) 
            sda_int <= op_tx(bit_cnt);   
            state <= s_op; 
      --writing OP code                 
      WHEN s_op =>                  
          
            IF(bit_cnt = 0) THEN          
              sda_int <= '1';          
              bit_cnt <= 7;              
              state <= s_slv_ack_op;          
            ELSE                          
              bit_cnt <= bit_cnt - 1;     
              sda_int <= op_tx(bit_cnt-1);
              state <= s_op;                   
            END IF;
      --get slave ACK after writing OP code 
      WHEN s_slv_ack_op =>                   --slave acknowledge bit (write)

            addr_rw <= addr & rw;         
            data_tx <= reg_adrr;           
            sda_int <= reg_adrr(bit_cnt); --write first bit of data
            state <= s_wr_reg;                 --go to write byte
      --writing register address   
      WHEN s_wr_reg =>                         --write byte of transaction

              IF(bit_cnt = 0) THEN             --write byte transmit finished
                sda_int <= '1';                --release sda for slave acknowledge
                bit_cnt <= 7;                  --reset bit counter for "byte" states
                state <= s_slv_ack_reg;             --go to slave acknowledge (write)
              ELSE                             --next clock cycle of write state
                bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
                sda_int <= data_tx(bit_cnt-1); --write next bit to bus
                state <= s_wr_reg;                   --continue writing
              END IF;
      --get slave ACKafter writing reg address  
      WHEN s_slv_ack_reg =>                   --slave acknowledge bit (write)

              addr_rw <= addr & rw; 

              IF    (rw = '0') then --start writing oparation 
                data_tx <= data_wr;           
                sda_int <= data_wr(bit_cnt); --write first bit of data
                rd_op <= '0';
                state <= s_wr;                 --go to write byte 
              else
                rd_op <= '1';
                state <= s_stop;
              --add P/Sr state -->Start state --> read /reas seq 
              end if;
            
		  WHEN s_wr =>                         --write byte of transaction

            IF(bit_cnt = 0) THEN             --write byte transmit finished
              sda_int <= '1';                --release sda for slave acknowledge
              bit_cnt <= 7;                  --reset bit counter for "byte" states
              if burst = '1' then
              regs_cnt <= regs_cnt - 1; 
              end if;
              state <= s_slv_ack2;             --go to slave acknowledge (write)
            ELSE                             --next clock cycle of write state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              sda_int <= data_tx(bit_cnt-1); --write next bit to bus
              if (burst = '1') then 
                regs_cnt <= to_integer(unsigned(burst_len));
              end if;
              state <= s_wr;                   --continue writing
            END IF;
          
		  WHEN s_rd =>                         --read byte of transaction

            IF(bit_cnt = 0) THEN             --read byte receive finished
              bit_cnt <= 7;                  --reset bit counter for "byte" states
              data_rd <= data_rx;            --output received data
              regs_cnt <= regs_cnt -1;
              state <= s_mstr_ack;            --go to master acknowledge
              rd_rdy <= '1';
            ELSE                             --next clock cycle of read state
              bit_cnt <= bit_cnt - 1;        --keep track of transaction bits
              state <= s_rd;                   --continue reading
            END IF;
          
		  WHEN s_slv_ack2 =>                   --slave acknowledge bit (write)
            if (burst = '1' and regs_cnt /= 0 and rw = '0' ) then 
              data_tx <= data_wr;           
              sda_int <= data_wr(bit_cnt); --write first bit of data
              state <= s_wr;
            elsif (rw = '0') then
              state <= s_stop; 
            end if;

            -- IF(ena = '1') THEN               --continue transaction
            --   addr_rw <= addr & rw;          --collect requested slave address and command
            --   data_tx <= data_wr;            --collect requested data to write
            --   -- IF(addr_rw = addr & rw) THEN   --continue transaction with another write
            --     -- sda_int <= data_wr(bit_cnt); --write first bit of data
            --     -- state <= s_wr;                 --go to write byte
            --   -- ELSE                           --continue transaction with a read or new slave
            --   state <= s_start;              --go to repeated start
            --   -- END IF;
            -- ELSE                             --complete transaction
            --   state <= s_stop;                 --go to stop bit
            -- END IF;
          
		  WHEN s_mstr_ack =>                   --master acknowledge bit after a read
            rd_rdy <= '0';
            IF(regs_cnt /= 0) THEN               --continue transaction
              sda_int <= '1';              --release sda from incoming data
              state <= s_rd;                 --go to read byte
  
            ELSE                             --complete transaction
              state <= s_stop;                 --go to stop bit
            END IF;
          
		  WHEN s_stop =>                       --stop bit of transaction
            if rd_op = '1' then
              state <= s_start; 
            else
            state <= s_ready;                  --go to idle state
            end if;
        END CASE;    
      
	  
	  
	  ELSIF(data_clk = '0' AND data_clk_prev = '1') THEN  --data clock falling edge
        CASE state IS
          --starting new transaction
		  WHEN s_start =>                  
            IF(scl_ena = '0') THEN                 
              scl_ena <= '1';                       --enable scl output
              ack_error <= '0';                     --reset acknowledge error output
            END IF;
          --receiving slave acknowledge (command)
		  WHEN s_slv_ack1 =>                          
            IF(sda /= '0' OR ack_error = '1') THEN  --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                     --set error output if no-acknowledge
            END IF;
          --receiving slave data
		  WHEN s_rd =>                                
            data_rx(bit_cnt) <= sda;                --receive current slave data bit
          --receiving slave acknowledge (write)
		  WHEN s_slv_ack2 =>                          
            IF(sda /= '0' OR ack_error = '1') THEN  --no-acknowledge or previous no-acknowledge
              ack_error <= '1';                     --set error output if no-acknowledge
            END IF;
          --disable scl
		  WHEN s_stop =>
            scl_ena <= '0';     
      WHEN s_slv_ack_op =>
        IF(sda /= '0' OR ack_error = '1') THEN  --no-acknowledge or previous no-acknowledge
        ack_error <= '1';                     --set error output if no-acknowledge
        END IF;      
      WHEN s_slv_ack_reg =>
        IF(sda /= '0' OR ack_error = '1') THEN  --no-acknowledge or previous no-acknowledge
          ack_error <= '1';                     --set error output if no-acknowledge
        END IF;  
      WHEN s_slv_ack_rd   =>
        IF(sda /= '0' OR ack_error = '1') THEN  --no-acknowledge or previous no-acknowledge
          ack_error <= '1';                     --set error output if no-acknowledge
        END IF;  
      WHEN OTHERS =>
        NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS;  

  --set sda output
  WITH state SELECT
    sda_ena_n <= data_clk_prev WHEN s_start,     --generate start condition
                 NOT data_clk_prev WHEN s_stop,  --generate stop condition
                 sda_int WHEN OTHERS;          --set to internal sda signal    
      
  --set scl and sda outputs
  scl <= '0' WHEN (scl_ena = '1' AND scl_clk = '0') ELSE 'Z';
  sda <= '0' WHEN sda_ena_n = '0' ELSE 'Z';
  

  process (clk)
  begin
    if rising_edge(scl) then
      debug_SR <= debug_SR(6 downto 0) &sda;
    end if;
  end process;
END logic;
