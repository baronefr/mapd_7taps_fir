-- MAPD - Barone Francesco Pio

-- This is a testbench to simulate a FIR filter with input provided from input file.
--  Run this simulation for at least 50 us every 200 samples provided.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.math_real.all;
use IEEE.numeric_std.all;
use work.fir_types.all;  -- use the previously declared types
use STD.textio.all; -- to read from files

entity tb_fir_simulation is
end tb_fir_simulation;


architecture tb of tb_fir_simulation is

    component fir_filter is
    port ( clk, active : in std_logic;    -- system clk, active = 0 resets the FIR filter
           coeffs : in coeff_array_type;  -- coefficients h(n) for the FIR filter
           Din_valid : in std_logic;     -- impulse to trigger the filter update
           Din  : in std_logic_vector(7 downto 0);      -- input data
           Dout : out std_logic_vector(  18 downto 0) );  -- output data
    end component;

    signal clk : std_logic := '0';
    signal trigger,  active : std_logic;
    signal ca : coeff_array_type;
    signal input  : std_logic_vector(7 downto 0);
    signal output : std_logic_vector(18 downto 0);
    signal DO : std_logic_vector(7 downto 0);
begin

    -- pluggin in the FIR
    ff : fir_filter port map (clk => clk, active => active, coeffs => ca, Din_valid => trigger,
                              Din => input , Dout => output);
    
    -- generating a system clock at 100MHz
    clk <= not clk after 5ns;
    
    -- FIR FILTER BEHAVIOUR: set coefficients (symmetric)
    
    -- 7 taps lowpass: cutoff 30Hz for 200Hz sampling, 8-bit scaling
    ca(0) <= X"01";  ca(1) <= X"0f";  ca(2) <= X"40";  ca(3) <= X"61";  --  + symmetric!
    
    
    -- waveform simulation from file
    simulate : process
    
        -- input file:
        file Fin : text is in "/home/baronefr/Documents/mapd/project/7taps_fir/demo/analysis/waveform_sample.txt";
         -- note: if the simulation is stuck here, there's a problem with the input file!
        
        -- output files
        file Fout  : text is out "/home/baronefr/Documents/mapd/project/7taps_fir/demo/analysis/vivado_simulation.txt";
        file Fout2 : text is out "/home/baronefr/Documents/mapd/project/7taps_fir/demo/analysis/vivado_simulation_8bit.txt";
        
        variable line_in, line_out : line; -- to store the lines from/to the files
        variable int_in, int_out : integer := 0;
    begin
        
        input <= X"00";
        
        trigger <= '0'; active <= '0'; wait for 25ns;
        active <= '1'; wait for 40ns;
        
        while not endfile(Fin) loop
            -- read data from input waveform file
            readline(Fin, line_in);  read(line_in, int_in); -- read line from input file & convert to int
            
            -- send the data to FIR
            trigger <='1';
            input <= std_logic_vector(to_signed(int_in, input'length));  -- store the int value in the input signal
            wait until rising_edge(clk);  trigger <='0';
            wait for 10 ns; wait until rising_edge(clk);
            
            -- store the outputs to file
            int_out := to_integer(signed(output));  -- store the output signal to an int variable
            write(line_out, int_out, left, 8);      -- convert the int to a line
            writeline(Fout, line_out);              -- write the line on the output file
            
            int_out := to_integer(signed(DO));
            write(line_out, int_out, left, 8);
            writeline(Fout2, line_out);
            wait for 200 ns;     
        end loop;
        active <= '0';   file_close(Fin);    file_close(Fout);
        wait;
    end process;
    
    -- 8bit output... should be the same int as output if there are no overflow issues!
    DO <= output(15 downto 8);
end tb;