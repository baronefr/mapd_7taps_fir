-- MAPD modA - Barone Francesco Pio
--   group:    Amjadi Bahador
--             Alba Roberto
--             Toledo Norberto
--             Khosravi Elham
--
--  This is a 7 taps FIR filter with symmetric multiplication optimization.
--  Furthermore, the coefficients of the filter can be changed runtime by interrupting
--   SW0 and sending the coefficient values through UART.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- this package is required for the definitions of the signals used in the FIR filter
package fir_types is
    -- observation: this code has a parametrized order variable, but the implementation assumes a 7 tap filter
    --    so don't change this parameter!
    constant order : integer := 6;  -- order of the filter   -- please note: N_taps = order + 1
    type coeff_array_type is array (0 to 3) of std_logic_vector(7 downto 0);  -- array for FIR coefficients
end package fir_types;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE IEEE.math_real.all;
use work.fir_types.all;  -- to use the previously declared types

entity fir_filter is
    port ( clk, active : in std_logic;    -- system clk, active = 0 resets the FIR filter
           coeffs : in coeff_array_type;  -- coefficients h(n) for the FIR filter
           Din_valid : in std_logic;     -- impulse to trigger the filter update
           Din  : in std_logic_vector(7 downto 0);      -- input data
           Dout : out std_logic_vector(  18 downto 0) );  -- output data
end fir_filter;

architecture behave of fir_filter is

    -- signals for the arithmetics
    type pipeline_type is array(0 to order) of signed(7 downto 0);  -- 8 bits
    signal x : pipeline_type := (others=> (others=>'0'));  -- array used to pipe the input signal
    
    type sum0_array_type is array (0 to 3) of signed(8  downto 0);  -- 9 bits (8 + 1)
    signal x0 : sum0_array_type := (others=> (others=>'0')); -- array used to sum the values matched to symm. coefficients
    
    type multipl_array_type is array (0 to 3) of signed(16 downto 0); -- 17 bit (9 + 8)
    signal m : multipl_array_type := (others=> (others=>'0'));  -- array to store the products  <= x0(i)*coeffs(i)
    
    type sum1_array_type is array (0 to 1) of signed(17  downto 0);   -- 18 bits
    signal s1 : sum1_array_type := (others=> (others=>'0'));
    
    signal output : std_logic_vector(18 downto 0);

begin
    pipeline : process(clk) is
    begin
        if active = '0' then
            x <= (others=> (others=>'0'));
        elsif rising_edge(clk) then
            if Din_valid = '1' then
                -- shift the data to insert the new value from input
                x <= signed(Din) & x(0 to order-1);
                -- output!
                
            end if;
        end if;
    end process;
    
    
    sum0 : process(clk) is
    begin        
        if rising_edge(clk) then
            if Din_valid = '1' then
                for i in 0 to 2 loop
                    x0(i) <= resize(x(i),9) + resize(x(6-i),9);
                end loop;
                x0(3) <= resize(x(3),9);
            end if;
        end if;
    end process;
    
    
    
    mults : process(clk) is
    begin
        if rising_edge(clk) then
            if Din_valid = '1' then
                for i in 0 to 3 loop
                    m(i) <= x0(i) * signed(coeffs(i));
                end loop;
            end if;         
        end if;
    end process;
    
    sum1 : process(clk) is
    begin
        if rising_edge(clk) then
            if Din_valid = '1' then
                for i in 0 to 1 loop
                    s1(i) <= resize(m(2*i),18) + resize(m(2*i+1),18);
                end loop;
            end if;    
        end if;
    end process;


    sum2 : process(clk) is
    begin
        if rising_edge(clk) then
            if Din_valid = '1' then
                output <= std_logic_vector( resize(s1(0),19) + resize(s1(1),19) );
            end if;
        end if;
    end process;
    
    Dout <= output;
    
end behave;



---------------------------
-- TARGET: FIR + UART    --
---------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.math_real.all;
use IEEE.numeric_std.all;
use work.fir_types.all;  -- use the previously declared types

entity fpga_fir is
    port (CLK100MHZ, fpga_rx : in std_logic; 
          fpga_tx : out std_logic;
          program_switch : in std_logic;
          led_operating : out std_logic;
          led_programming : out std_logic;
          led_programming_ok : out std_logic );
end fpga_fir;

architecture behave of fpga_fir is

    -- components   
    component uart_tx_module is
        port( clk, data_valid : in  std_logic;
              data_to_send : in  std_logic_vector(7 downto 0);
              busy, uart_tx : out std_logic );
    end component;
    
    component uart_rx_module is
        port( clk, uart_rx  : in  std_logic;
              valid         : out std_logic;
              received_data : out std_logic_vector(7 downto 0));
    end component;

    component fir_filter is
    port ( clk, active : in std_logic;    -- system clk, active = 0 resets the FIR filter
           coeffs : in coeff_array_type;  -- coefficients h(n) for the FIR filter
           Din_valid : in std_logic;     -- impulse to trigger the filter update
           Din  : in std_logic_vector(7 downto 0);      -- input data
           Dout : out std_logic_vector(  18 downto 0) );  -- output data
    end component;
    
    -- signals
    signal ca : coeff_array_type :=  ( 0 => X"01", 1 => X"0f", 2 => X"40", 3 => X"61");   -- default fir coefficients
    signal rx_busy, tx_busy  : std_logic;   -- dummy signals
    signal programming, active : std_logic;   -- 
    signal rx_validate : std_logic;        -- trigger the transmission
    signal vin, vout : std_logic_vector( 7 downto 0);
    signal output : std_logic_vector( 18 downto 0);
    
    signal counter : unsigned(7 downto 0) := (others => '0');
    constant coeffs_no : unsigned(7 downto 0) := to_unsigned(4, 8);  -- inset number of coefficients
begin
    
    -- UART interface
    uurx : uart_rx_module port map ( clk => CLK100MHZ, uart_rx => fpga_rx, valid => rx_validate, received_data => vin);
    uutx : uart_tx_module port map ( clk => CLK100MHZ, data_to_send => vout, data_valid => rx_validate, busy => tx_busy, uart_tx => fpga_tx);
    
    -- FIR filter
    ff : fir_filter port map (clk => CLK100MHZ, active => active, coeffs => ca, 
                              Din_valid => rx_validate, Din => vin , Dout => output);
    
    

    -- user interface: use the switch to select between filter operations & coefficients programming
    ui : process(CLK100MHZ) is
    begin
        if rising_edge(CLK100MHZ) then
            if program_switch = '1' then
                -- FIR filter operating
                active <= '1';
                led_operating <= '1';
                vout <= output(15 downto 8);  -- FIR filter output bit scaling
                
                programming <= '0';
                led_programming <= '0';
                
            else
                -- set the coefficients
                active <= '0';
                led_operating <= '0';
                
                programming <= '1';
                led_programming <= '1';
            end if;
        end if;
    end process;
    
    
    -- process to set the coefficients values from UART interface
    program_mode : process(CLK100MHZ) is
    begin
        if rising_edge(CLK100MHZ) then
            if programming = '1' then
                
                if counter = coeffs_no then
                    led_programming_ok <= '1';
                elsif rx_validate = '1' then
                    ca( to_integer(counter) ) <= vin;
                    counter <= counter + 1;
                    led_programming_ok <= '0';
                end if;
                
            else
                counter <= (others => '0');
                led_programming_ok <= '0';
            end if;
        end if;
    end process;    
    
end behave;