--------------------------------------------------------------------------------
--
--   FileName:         i2c_master.vhd
--   Dependencies:     none
--   Design Software:  Quartus II 64-bit Version 13.1 Build 162 SJ Full Version
--
--   HDL CODE IS PROVIDED "AS IS."  DIGI-KEY EXPRESSLY DISCLAIMS ANY
--   WARRANTY OF ANY KIND, WHETHER EXPRESS OR IMPLIED, INCLUDING BUT NOT
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
--   PARTICULAR PURPOSE, OR NON-INFRINGEMENT. IN NO EVENT SHALL DIGI-KEY
--   BE LIABLE FOR ANY INCIDENTAL, SPECIAL, INDIRECT OR CONSEQUENTIAL
--   DAMAGES, LOST PROFITS OR LOST DATA, HARM TO YOUR EQUIPMENT, COST OF
--   PROCUREMENT OF SUBSTITUTE GOODS, TECHNOLOGY OR SERVICES, ANY CLAIMS
--   BY THIRD PARTIES (INCLUDING BUT NOT LIMITED TO ANY DEFENSE THEREOF),
--   ANY CLAIMS FOR INDEMNITY OR CONTRIBUTION, OR OTHER SIMILAR COSTS.
--
--   Version History
--   Version 1.0 11/1/2012 Scott Larson
--     Initial Public Release
--   Version 2.0 06/20/2014 Scott Larson
--     Added ability to interface with different slaves in the same transaction
--     Corrected ack_error bug where ack_error went 'Z' instead of '1' on error
--     Corrected timing of when ack_error signal clears
--   Version 2.1 10/21/2014 Scott Larson
--     Replaced gated clock with clock enable
--     Adjusted timing of SCL during start and stop conditions
-- 
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.std_logic_unsigned.all;

ENTITY i2c_master IS
  GENERIC(
    INPUT_CLK : INTEGER := 100_000_000; --input clock speed from user logic in Hz
    BUS_CLK   : INTEGER := 400_000);   --speed the i2c bus (SCL) will run at in Hz
  PORT(
    CLK       : IN     STD_LOGIC;                    --system clock
    RESET_N   : IN     STD_LOGIC;                    --active low reset
    ENA       : IN     STD_LOGIC;                    --latch in command
    ADDR      : IN     STD_LOGIC_VECTOR(6 DOWNTO 0); --address of target slave
    RW        : IN     STD_LOGIC;                    --'0' is write, '1' is read
    DATA_WR   : IN     STD_LOGIC_VECTOR(7 DOWNTO 0); --data to write to slave
    BUSY      : OUT    STD_LOGIC;                    --indicates transaction in progress
    DATA_RD   : OUT    STD_LOGIC_VECTOR(7 DOWNTO 0); --data read from slave
    ACK_ERROR : BUFFER STD_LOGIC;                    --flag if improper acknowledge from slave
    SDA       : INOUT  STD_LOGIC;                    --serial data output of i2c bus
    SCL       : INOUT  STD_LOGIC);                   --serial clock output of i2c bus
END i2c_master;

ARCHITECTURE logic OF i2c_master IS
  CONSTANT DIVIDER  :  INTEGER := (INPUT_CLK/BUS_CLK)/4; --number of clocks in 1/4 cycle of SCL
  TYPE MACHINE IS(READY, START, COMMAND, SLV_ACK1, WR, RD, SLV_ACK2, MSTR_ACK, STOP); --needed states
  SIGNAL STATE         : MACHINE;                        --state machine
  SIGNAL DATA_CLK      : STD_LOGIC;                      --data clock for SDA
  SIGNAL DATA_CLK_PREV : STD_LOGIC;                      --data clock during previous system clock
  SIGNAL SCL_CLK       : STD_LOGIC;                      --constantly running internal SCL
  SIGNAL SCL_ENA       : STD_LOGIC := '0';               --enables internal SCL to output
  SIGNAL SDA_INT       : STD_LOGIC := '1';               --internal SDA
  SIGNAL SDA_ENA_N     : STD_LOGIC;                      --enables internal SDA to output
  SIGNAL ADDR_RW       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --latched in address and read/write
  SIGNAL DATA_TX       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --latched in data to write to slave
  SIGNAL DATA_RX       : STD_LOGIC_VECTOR(7 DOWNTO 0);   --data received from slave
  SIGNAL BIT_CNT       : INTEGER RANGE 0 TO 7 := 7;      --tracks bit number in transaction
  SIGNAL STRETCH       : STD_LOGIC := '0';               --identifies if slave is stretching SCL
  SIGNAL DATA_CLK_M : STD_LOGIC;
BEGIN

  --generate the timing for the bus clock (SCL_CLK) and the data clock (DATA_CLK)
  PROCESS(CLK, RESET_N)
    VARIABLE COUNT  :  INTEGER RANGE 0 TO DIVIDER*4;  --timing for clock generation
  BEGIN
    IF(RESET_N = '0') THEN                --reset asserted
      STRETCH <= '0';
      COUNT := 0;
    ELSIF(CLK'EVENT AND CLK = '1') THEN
      DATA_CLK_PREV <= DATA_CLK;          --store previous value of data clock
      IF(COUNT = DIVIDER*4-1) THEN        --end of timing cycle
        COUNT := 0;                       --reset timer
      ELSIF(STRETCH = '0') THEN           --clock stretching from slave not detected
        COUNT := COUNT + 1;               --continue clock generation timing
      END IF;
      CASE COUNT IS
        WHEN 0 TO DIVIDER-1 =>            --first 1/4 cycle of clocking
          SCL_CLK <= '0';
          DATA_CLK <= '0';
        WHEN DIVIDER TO DIVIDER*2-1 =>    --second 1/4 cycle of clocking
          SCL_CLK <= '0';
          DATA_CLK <= '1';
        WHEN DIVIDER*2 TO DIVIDER*3-1 =>  --third 1/4 cycle of clocking
          SCL_CLK <= '1';                 --release SCL
          IF(SCL = '0') THEN              --detect if slave is stretching clock
            STRETCH <= '1';
          ELSE
            STRETCH <= '0';
          END IF;
          DATA_CLK <= '1';
        WHEN OTHERS =>                    --last 1/4 cycle of clocking
          SCL_CLK <= '1';
          DATA_CLK <= '0';
      END CASE;
    END IF;
  END PROCESS;

  --state machine and writing to SDA during SCL low (DATA_CLK rising edge)
  PROCESS(CLK, RESET_N)
  BEGIN
    IF(RESET_N = '0') THEN                 --reset asserted
      STATE <= READY;                      --return to initial state
      BUSY <= '1';                         --indicate not available
      SCL_ENA <= '0';                      --sets SCL high impedance
      SDA_INT <= '1';                      --sets SDA high impedance
      ACK_ERROR <= '0';                    --clear acknowledge error flag
      BIT_CNT <= 7;                        --restarts data bit counter
      DATA_RD <= "00000000";               --clear data read port
    ELSIF(CLK'EVENT AND CLK = '1') THEN
      IF(DATA_CLK = '1' AND DATA_CLK_PREV = '0') THEN  --data clock rising edge
        CASE STATE IS
          WHEN READY =>                      --idle state
            IF(ENA = '1') THEN               --transaction requested
              BUSY <= '1';                   --flag busy
              ADDR_RW <= ADDR & RW;          --collect requested slave address and command
              DATA_TX <= DATA_WR;            --collect requested data to write
              STATE <= START;                --go to start bit
            ELSE                             --remain idle
              BUSY <= '0';                   --unflag busy
              STATE <= READY;                --remain idle
            END IF;
          WHEN START =>                      --start bit of transaction
            BUSY <= '1';                     --resume busy if continuous mode
            SDA_INT <= ADDR_RW(BIT_CNT);     --set first address bit to bus
            STATE <= COMMAND;                --go to command
          WHEN COMMAND =>                    --address and command byte of transaction
            IF(BIT_CNT = 0) THEN             --command transmit finished
              SDA_INT <= '1';                --release SDA for slave acknowledge
              BIT_CNT <= 7;                  --reset bit counter for "byte" states
              STATE <= SLV_ACK1;             --go to slave acknowledge (command)
            ELSE                             --next clock cycle of command state
              BIT_CNT <= BIT_CNT - 1;        --keep track of transaction bits
              SDA_INT <= ADDR_RW(BIT_CNT-1); --write address/command bit to bus
              STATE <= COMMAND;              --continue with command
            END IF;
          WHEN SLV_ACK1 =>                   --slave acknowledge bit (command)
            IF(ADDR_RW(0) = '0') THEN        --write command
              SDA_INT <= DATA_TX(BIT_CNT);   --write first bit of data
              STATE <= WR;                   --go to write byte
            ELSE                             --read command
              SDA_INT <= '1';                --release SDA from incoming data
              STATE <= RD;                   --go to read byte
            END IF;
          WHEN WR =>                         --write byte of transaction
            BUSY <= '1';                     --resume busy if continuous mode
            IF(BIT_CNT = 0) THEN             --write byte transmit finished
              SDA_INT <= '1';                --release SDA for slave acknowledge
              BIT_CNT <= 7;                  --reset bit counter for "byte" states
              BUSY <= '0';                   --modified
              STATE <= SLV_ACK2;             --go to slave acknowledge (write)
            ELSE                             --next clock cycle of write state
              BIT_CNT <= BIT_CNT - 1;        --keep track of transaction bits
              SDA_INT <= DATA_TX(BIT_CNT-1); --write next bit to bus
              STATE <= WR;                   --continue writing
            END IF;
          WHEN RD =>                         --read byte of transaction
            BUSY <= '1';                     --resume busy if continuous mode
            IF(BIT_CNT = 0) THEN             --read byte receive finished
              IF(ENA = '1' AND ADDR_RW = ADDR & RW) THEN  --continuing with another read at same address
                SDA_INT <= '0';              --acknowledge the byte has been received
              ELSE                           --stopping or continuing with a write
                SDA_INT <= '1';              --send a no-acknowledge (before stop or repeated start)
              END IF;
              BIT_CNT <= 7;                  --reset bit counter for "byte" states
              DATA_RD <= DATA_RX;            --output received data
              STATE <= MSTR_ACK;             --go to master acknowledge
            ELSE                             --next clock cycle of read state
              BIT_CNT <= BIT_CNT - 1;        --keep track of transaction bits
              STATE <= RD;                   --continue reading
            END IF;
          WHEN SLV_ACK2 =>                   --slave acknowledge bit (write)
            IF(ENA = '1') THEN               --continue transaction
              ADDR_RW <= ADDR & RW;          --collect requested slave address and command
              DATA_TX <= DATA_WR;            --collect requested data to write
              IF(ADDR_RW = ADDR & RW) THEN   --continue transaction with another write
                BUSY <= '1';
                SDA_INT <= DATA_WR(BIT_CNT); --write first bit of data
                STATE <= WR;                 --go to write byte
              ELSE                           --continue transaction with a read or new slave
                STATE <= START;              --go to repeated start
              END IF;
            ELSE                             --complete transaction
              STATE <= STOP;                 --go to stop bit
            END IF;
          WHEN MSTR_ACK =>                   --master acknowledge bit after a read
            IF(ENA = '1') THEN               --continue transaction
              BUSY <= '0';                   --continue is accepted and data received is available on bus
              ADDR_RW <= ADDR & RW;          --collect requested slave address and command
              DATA_TX <= DATA_WR;            --collect requested data to write
              IF(ADDR_RW = ADDR & RW) THEN   --continue transaction with another read
                SDA_INT <= '1';              --release SDA from incoming data
                STATE <= RD;                 --go to read byte
              ELSE                           --continue transaction with a write or new slave
                STATE <= START;              --repeated start
              END IF;    
            ELSE                             --complete transaction
              STATE <= STOP;                 --go to stop bit
            END IF;
          WHEN STOP =>                       --stop bit of transaction
            BUSY <= '0';                     --unflag busy
            STATE <= READY;                  --go to idle state
        END CASE;    
      ELSIF(DATA_CLK = '0' AND DATA_CLK_PREV = '1') THEN  --data clock falling edge
        CASE STATE IS
          WHEN START =>                  
            IF(SCL_ENA = '0') THEN                  --starting new transaction
              SCL_ENA <= '1';                       --enable SCL output
              ACK_ERROR <= '0';                     --reset acknowledge error output
            END IF;
          WHEN SLV_ACK1 =>                          --receiving slave acknowledge (command)
            IF(SDA /= '0' OR ACK_ERROR = '1') THEN  --no-acknowledge or previous no-acknowledge
              ACK_ERROR <= '1';                     --set error output if no-acknowledge
            END IF;
          WHEN RD =>                                --receiving slave data
            DATA_RX(BIT_CNT) <= SDA;                --receive current slave data bit
          WHEN SLV_ACK2 =>                          --receiving slave acknowledge (write)
            IF(SDA /= '0' OR ACK_ERROR = '1') THEN  --no-acknowledge or previous no-acknowledge
              ACK_ERROR <= '1';                     --set error output if no-acknowledge
            END IF;
          WHEN STOP =>
            SCL_ENA <= '0';                         --disable SCL
          WHEN OTHERS =>
            NULL;
        END CASE;
      END IF;
    END IF;
  END PROCESS;  

  --set SDA output
  DATA_CLK_M <= DATA_CLK_PREV AND DATA_CLK;
  WITH STATE SELECT
    SDA_ENA_N <= DATA_CLK WHEN START,     --generate start condition
                 NOT DATA_CLK_M WHEN STOP,  --generate stop condition
                 SDA_INT WHEN OTHERS;     --set to internal SDA signal    
      
  --set SCL and SDA outputs
  SCL <= '0' WHEN (SCL_ENA = '1' AND SCL_CLK = '0') ELSE 'Z';
  SDA <= '0' WHEN SDA_ENA_N = '0' ELSE 'Z';
  
END logic;
