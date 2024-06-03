library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock_generator is
  generic(clock_in_speed: INTEGER := 100_000_000; clock_out_speed: INTEGER := 100_000);
  port(
    clock_in: in std_logic;
    clock_out: out std_logic);
end entity clock_generator;

architecture rtl of clock_generator is

  function num_bits(n: natural) return natural is
  begin
    if n > 0 then
      return 1 + num_bits(n / 2);
    else
      return 1;
    end if;
  end num_bits;

  constant max_counter: natural := clock_in_speed / clock_out_speed / 2;
  constant counter_bits: natural := num_bits(max_counter);

  signal counter: unsigned(counter_bits - 1 downto 0) := (others => '0');
  signal clock_signal: std_logic;

begin
  update_counter: process(clock_in)
  begin
    if clock_in'event and clock_in = '1' then
      if counter = max_counter then
        counter <= to_unsigned(0, counter_bits);
        clock_signal <= not clock_signal;
      else
        counter <= counter + 1;
      end if;
    end if;
  end process;
  
  clock_out <= clock_signal;
end architecture rtl;