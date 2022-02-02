----  MAPD modA 

-- this is the entity definition for an UART interface operating under a 100MHz clk


------------------------------------------------------------------------
-- UART:   baudrate generator


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity baudrate_generator is
    port( clk        : in  std_logic;
          baudrate_out : out std_logic);
end entity baudrate_generator;


architecture rtl of baudrate_generator is
    signal counter   : unsigned(9 downto 0) := (others => '0');
    constant divisor : unsigned(9 downto 0) := to_unsigned(867, 10);
begin
    main : process (clk) is
    begin  -- process main
        if rising_edge(clk) then          -- rising clk edge
            counter <= counter + 1;
            if counter = divisor then
                baudrate_out <= '1';
                counter      <= (others => '0');
            else
                baudrate_out <= '0';
            end if;
        end if;
    end process main;
end architecture rtl;




------------------------------------------------------------------------
-- UART:   sampler generator


library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sampler_generator is
    port( clk        : in  std_logic;
          uart_rx      : in  std_logic;
          baudrate_out : out std_logic);
end entity sampler_generator;

architecture rtl of sampler_generator is

  type state_t is (idle_s, start_s, bit0_s, bit1_s, bit2_s, bit3_s, bit4_s, bit5_s, bit6_s, bit7_s, bit8_s, stop_s);
  signal state : state_t := idle_s;

  signal counter        : unsigned(10 downto 0) := (others => '0');
  signal delay_counter  : unsigned(10 downto 0) := (others => '0');
  constant divisor      : unsigned(10 downto 0) := to_unsigned(867, 11);
  constant half_divisor : unsigned(10 downto 0) := to_unsigned(433, 11);
  signal busy           : std_logic             := '0';
  signal pulse_out      : std_logic;
  signal enable_counter : std_logic             := '0';
  signal enable_delay   : std_logic             := '0';
begin

  --
  pulse_generator : process (clk) is
  begin  -- process main
    if rising_edge(clk) then          -- rising clk edge
      if enable_counter = '1' then
        counter <= counter + 1;
        if counter = divisor then
          pulse_out <= '1';
          counter   <= (others => '0');
        else
          pulse_out <= '0';
        end if;
      else
        counter <= (others => '0');
      end if;
    end if;
  end process pulse_generator;

  state_machine : process (clk) is
  begin  -- process state_machine
    if rising_edge(clk) then          -- rising clk edge
      case state is
        when idle_s =>
          enable_counter <= '0';
          if uart_rx = '0' then
            state <= start_s;
          end if;
        when start_s =>
          -- enable baudrate_generator
          enable_counter <= '1';
          if pulse_out = '1' then
            state <= bit0_s;
          end if;
        when bit0_s =>
          if pulse_out = '1' then
            state <= bit1_s;
          end if;
        when bit1_s =>
          if pulse_out = '1' then
            state <= bit2_s;
          end if;
        when bit2_s =>
          if pulse_out = '1' then
            state <= bit3_s;
          end if;
        when bit3_s =>
          if pulse_out = '1' then
            state <= bit4_s;
          end if;
        when bit4_s =>
          if pulse_out = '1' then
            state <= bit5_s;
          end if;
        when bit5_s =>
          if pulse_out = '1' then
            state <= bit6_s;
          end if;
        when bit6_s =>
          if pulse_out = '1' then
            state <= bit7_s;
          end if;
        when bit7_s =>
          if pulse_out = '1' then
            state <= idle_s;
          end if;
        when others => null;
      end case;
    end if;
  end process state_machine;

  delay_line : process (clk) is
  begin  -- process delay_line
    if rising_edge(clk) then          -- rising clk edge
      if pulse_out = '1' then
        --start_count
        enable_delay <= '1';
      end if;
      if delay_counter = half_divisor then
        enable_delay <= '0';
        baudrate_out <= '1';
      --end count
      else
        baudrate_out <= '0';
      end if;
      if enable_delay = '1' then
        delay_counter <= delay_counter + 1;
      else
        delay_counter <= (others => '0');
      end if;
    end if;
  end process delay_line;

end architecture rtl;



------------------------------------------------------------------------
-- UART:   uart receiver
------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;

entity uart_rx_module is
    port( clk, uart_rx  : in  std_logic;
          valid         : out std_logic;
          received_data : out std_logic_vector(7 downto 0));
end entity uart_rx_module;


architecture str of uart_rx_module is

  type state_t is (idle_s, start_s, bit0_s, bit1_s, bit2_s, bit3_s, bit4_s, bit5_s, bit6_s, bit7_s, bit8_s, stop_s);
  signal state : state_t := idle_s;

  signal baudrate_out : std_logic;
  signal received_data_s : std_logic_vector(7 downto 0);

  component sampler_generator is
    port (
      clk        : in  std_logic;
      uart_rx      : in  std_logic;
      baudrate_out : out std_logic);
  end component sampler_generator;


begin  -- architecture str

  sampler_generator_1 : sampler_generator
    port map (
      clk        => clk,
      uart_rx      => uart_rx,
      baudrate_out => baudrate_out);


  main : process (clk) is
  begin  -- process main
    if rising_edge(clk) then          -- rising clk edge
      case state is
        when idle_s =>
          received_data_s <= (others => '0');
          valid         <= '0';
          if uart_rx = '0' then
            state <= start_s;
          end if;
        when start_s =>
          if baudrate_out = '1' then
            received_data_s(0) <= uart_rx;
            state <= bit0_s;
          end if;
        when bit0_s =>
          if baudrate_out = '1' then
            received_data_s(1) <= uart_rx;
            state            <= bit1_s;
          end if;
        when bit1_s =>
          if baudrate_out = '1' then
            received_data_s(2) <= uart_rx;
            state            <= bit2_s;
          end if;
        when bit2_s =>
          if baudrate_out = '1' then
            received_data_s(3) <= uart_rx;
            state            <= bit3_s;
          end if;
        when bit3_s =>
          if baudrate_out = '1' then
            received_data_s(4) <= uart_rx;
            state            <= bit4_s;
          end if;
        when bit4_s =>
          if baudrate_out = '1' then
            received_data_s(5) <= uart_rx;
            state            <= bit5_s;
          end if;
        when bit5_s =>
          if baudrate_out = '1' then
            received_data_s(6) <= uart_rx;
            state            <= bit6_s;
          end if;
        when bit6_s =>
          if baudrate_out = '1' then
            received_data_s(7) <= uart_rx;
            state            <= bit7_s;
          end if;
        when bit7_s =>
          if baudrate_out = '1' then
            valid            <= '1';
            received_data <= received_data_s;
            state            <= idle_s;
          end if;
        when others => null;
      end case;
    end if;
  end process main;
end architecture str;




------------------------------------------------------------------------
-- UART:   uart transmitter
------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity uart_tx_module is
    port( clk, data_valid : in  std_logic;
          data_to_send : in  std_logic_vector(7 downto 0);
          busy, uart_tx : out std_logic);
end entity uart_tx_module;


architecture rtl of uart_tx_module is

  component baudrate_generator is
    port ( clk        : in  std_logic;
           baudrate_out : out std_logic);
  end component baudrate_generator;

  signal baudrate_out : std_logic;
  -- state machine signals
  type state_t is (idle_s, data_valid_s, start_s, bit0_s, bit1_s, bit2_s, bit3_s, bit4_s, bit5_s, bit6_s, bit7_s, bit8_s, stop_s);
  signal state : state_t := idle_s;
  
begin  -- architecture rtl

  baudrate_generator_1 : baudrate_generator
    port map (
      clk        => clk,
      baudrate_out => baudrate_out);


  -- State Machine
  main_state_machine : process (clk) is
  begin  -- process main_state_machine
    if rising_edge(clk) then          -- rising clk edge
      case state is
        when idle_s =>
          busy    <= '0';
          uart_tx <= '1';
          if data_valid = '1' then
            state <= data_valid_s;
          end if;
        when data_valid_s =>
          busy <= '1';
          if baudrate_out = '1' then
            state <= start_s;
          end if;
        when start_s =>
          uart_tx <= '0';
          if baudrate_out = '1' then
            state <= bit0_s;
          end if;
        when bit0_s =>
          uart_tx <= data_to_send(0);
          if baudrate_out = '1' then
            state <= bit1_s;
          end if;
        when bit1_s =>
          uart_tx <= data_to_send(1);
          if baudrate_out = '1' then
            state <= bit2_s;
          end if;
        when bit2_s =>
          uart_tx <= data_to_send(2);
          if baudrate_out = '1' then
            state <= bit3_s;
          end if;
        when bit3_s =>
          uart_tx <= data_to_send(3);
          if baudrate_out = '1' then
            state <= bit4_s;
          end if;
        when bit4_s =>
          uart_tx <= data_to_send(4);
          if baudrate_out = '1' then
            state <= bit5_s;
          end if;
        when bit5_s =>
          uart_tx <= data_to_send(5);
          if baudrate_out = '1' then
            state <= bit6_s;
          end if;
        when bit6_s =>
          uart_tx <= data_to_send(6);
          if baudrate_out = '1' then
            state <= bit7_s;
          end if;
        when bit7_s =>
          uart_tx <= data_to_send(7);
          if baudrate_out = '1' then
            state <= stop_s;
          end if;
        when stop_s =>
          uart_tx <= '1';
          if baudrate_out = '1' then
            state <= idle_s;
          end if;
        when others => null;
      end case;
    end if;
  end process main_state_machine;

end architecture rtl;