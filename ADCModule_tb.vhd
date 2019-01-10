LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb1 IS
END tb1;
 
ARCHITECTURE behavior OF tb1 IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT ADCModule
    PORT(
         clk_50Mhz : IN  std_logic;
         cs : OUT  std_logic;
         din : OUT  std_logic;
         dout : IN  std_logic;
         clk_10Mhz : OUT  std_logic;
         tx_out : OUT  std_logic;
         led_out : OUT  std_logic_vector(7 downto 0);
         state_adc : OUT  std_logic_vector(1 downto 0);
         state_uart : OUT  std_logic_vector(1 downto 0);
			clk_uart_out : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_50Mhz : std_logic := '0';
   signal dout : std_logic := '0';

 	--Outputs
   signal cs : std_logic;
   signal din : std_logic;
   signal clk_10Mhz : std_logic;
   signal tx_out : std_logic;
   signal led_out : std_logic_vector(7 downto 0);
   signal state_adc : std_logic_vector(1 downto 0);
	signal state_uart : std_logic_vector(1 downto 0);
   signal clk_uart_out : std_logic;

   -- Clock period definitions
   constant clk_50Mhz_period : time := 20 ns;
  
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: ADCModule PORT MAP (
          clk_50Mhz => clk_50Mhz,
          cs => cs,
          din => din,
          dout => dout,
          clk_10Mhz => clk_10Mhz,
          tx_out => tx_out,
          led_out => led_out,
          state_adc => state_adc,
			 state_uart => state_uart,
          clk_uart_out => clk_uart_out
        );

   -- Clock process definitions
   clk_50Mhz_process :process
   begin
		clk_50Mhz <= '0';
		wait for clk_50Mhz_period/2;
		clk_50Mhz <= '1';
		wait for clk_50Mhz_period/2;
   end process;
 
   -- Stimulus process
   stim_proc: process
   begin		
   wait for 1380 ns; dout <= '1';
	wait;
   end process;

END;
