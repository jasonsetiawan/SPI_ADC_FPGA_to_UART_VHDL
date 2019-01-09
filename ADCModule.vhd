library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity ADCModule is
	
	Generic(
		clk_scaler : integer := 5; 	-- Used for ADC Clock :: ADC clock = 50Mhz/clk_scaler 
		byte_long : integer := 18;		-- Used for length of SPI transferred bits. 
		baud_scaler : integer := 434  -- Used for UART Baud Rate :: Baudrate = 50MHz/baud_scaler
	);
	
	Port(
	-- Main clock which is used in the design
		clk_50Mhz : in STD_LOGIC; 	-- Connect to Clock50MHz - V11
		
	-- For ADC-SPI Interface with Main Processor
		cs : out STD_LOGIC;			-- Connect to CONVST - U9
		din : out STD_LOGIC;			-- Connect to SDI - AC4
		dout : in STD_LOGIC;			-- Connect to SDO - AD4
		clk_10Mhz : out STD_LOGIC; -- Connect to SCK - V10
	
	-- For Serial Out (UART)
		tx_out : out STD_LOGIC; 	-- Connect to GPIO_0[1] - AF7 
	
	-- Testbench Parameter
		led_out : out STD_LOGIC_VECTOR(7 downto 0) := "00000000";
		state_adc : out STD_LOGIC_VECTOR (1 downto 0) := "00";
		state_uart : out STD_LOGIC_VECTOR (1 downto 0) := "00";
		clk_uart_out : out STD_LOGIC); -- Connect to GPIO_0[0] - V12

end entity;

architecture spiMaster_arc of ADCModule is

-- SPI-ADC State
type spi_state is (idle, execute); -- Main State
type execute_state is (din_state, dout_state); -- Inside 'execute' state

-- UART state
type uart_tx_state is (idle, start, data, stop);

-- Signal used in ADS-SPI to FPGA interface
signal trig_spi : spi_state := execute;								-- signal for state declaration, initiate spi state : idle 
signal trig_execute : execute_state := din_state;  
signal scale_cnt : integer range 0 to clk_scaler - 1 := 0;
signal clk_10Mhz_temp : STD_LOGIC := '1';
signal adc_data_temp : STD_LOGIC_VECTOR(11 downto 0);
signal enable_out : STD_LOGIC;
signal din_byte : STD_LOGIC_VECTOR(0 to 5):= "100010";
signal din_index : integer range 0 to 5 := 0;
signal dout_index : integer range 0 to 11 := 0;
signal byte_cnt : integer range 0 to byte_long - 1 := 0;

-- Signal used in UART
signal uart_tx_sig : uart_tx_state := idle;
signal send_cnt : integer range 0 to 4;
signal baudscale_cnt : integer range 0 to baud_scaler - 1;
signal clk_temp : STD_LOGIC := '0';
signal uart_tx_data : STD_LOGIC_VECTOR(7 downto 0);
signal uart_byte_cnt : integer range 0 to 10 := 0;
signal adc_data1, adc_data2, adc_data3 : std_logic_vector(3 downto 0);

begin
-- Clock scaling proccess for ADC-SPI
	clock_scale_proc : process(clk_50Mhz)
	begin
	
		if rising_edge(clk_50Mhz) then
			if scale_cnt = clk_scaler -1  then
				clk_10Mhz_temp <= not(clk_10Mhz_temp);
				scale_cnt <= 0;
			else
				scale_cnt <= scale_cnt + 1;
			end if;
		end if;
	end process clock_scale_proc;
	clk_10Mhz <= clk_10Mhz_temp;

-- Baud rate setting
	baud_scale_proc : process(clk_50Mhz)
   begin
     if rising_edge(clk_50Mhz) then
       if baudscale_cnt = baud_scaler - 1 then
          clk_temp <= not (clk_temp);
			 baudscale_cnt <= 0;
       else
          baudscale_cnt <= baudscale_cnt + 1;
       end if;
     end if;
   end process baud_scale_proc;
   clk_uart_out <= clk_temp;

-- ADC to FPGA using SPI
	spi_proc : process(clk_10Mhz_temp)
	begin
	
	if rising_edge(clk_10Mhz_temp) then
		case trig_spi is
				when idle =>
--					adc_data <= adc_data_temp;
					led_out <= adc_data_temp(7 downto 0);
					adc_data_temp <= "000000000000";
--					adc_data_tempo <= "000000000000";
					din <= '0';
					cs <= '1';
					byte_cnt <= 0;
					state_adc <= "00";					
				when execute =>
					trig_spi <= execute;
					cs <= '0';
					case trig_execute is
						when din_state =>
							if byte_cnt = 5 then
								din <= din_byte(din_index);
								trig_execute <= dout_state;
								byte_cnt <= 0;
								din_index <= 0;
							else
								byte_cnt <= byte_cnt + 1;
								din <= din_byte(din_index);
								din_index <= din_index + 1;
								state_adc <= "01";
								end if;
						when dout_state =>
							din <= '0';
							if byte_cnt = 11 then
								adc_data_temp(dout_index) <= dout;
--								adc_data_tempo(dout_index) <= dout;
								dout_index <= 0;
								byte_cnt <= 0;
								trig_execute <= din_state;
								trig_spi <= idle;
								uart_tx_sig <= start;
								uart_byte_cnt <= 0;
							else
								adc_data_temp(dout_index) <= dout;
--								adc_data_tempo(dout_index) <= dout;
								byte_cnt <= byte_cnt + 1;
								dout_index <= dout_index + 1;
								state_adc <= "10";
							end if;						
					end case;
--					count <= byte_cnt;
--					dout_i <= dout_index;					
			end case;
		end if;

-- FPGA to PC using UART		
		if rising_edge(clk_temp) then
            if send_cnt < 4 then
--               data_out <= uart_tx_data;
                case uart_tx_sig is
                when idle =>
                    if uart_byte_cnt = 0 then
                        tx_out <= '1';
								state_uart <= "00";
                        uart_byte_cnt <= 0;
                    end if;
                when start =>
						  state_uart <= "01";
                    tx_out <= '0';
                    uart_tx_sig <= data;
                when data =>
                    state_uart <= "10";                         
                    adc_data1 <= adc_data_temp(11 downto 8);
                    adc_data2 <= adc_data_temp(7 downto 4);
                    adc_data3 <= adc_data_temp(3 downto 0);
                    case (send_cnt) is
                      when 0 => uart_tx_data <= x"41";
                      when 1 => uart_tx_data <= "0000" & adc_data1;
                      when 2 => uart_tx_data <= adc_data2 & adc_data3;
                      when 3 => uart_tx_data <= x"0A";
                      when others => uart_tx_data <= "00000000";
                    end case;
						  if uart_byte_cnt = 7 then
                        tx_out <= uart_tx_data(byte_cnt);
                        uart_byte_cnt <= 0;
                        uart_tx_sig <= stop;
                    else
                        tx_out <= uart_tx_data(byte_cnt);
                        uart_byte_cnt <= uart_byte_cnt + 1;
                    end if;
                   
                when stop =>
						  state_uart <= "11";
                    tx_out <= '1';
						  if send_cnt = 3 then
							uart_tx_sig <= idle; 
							trig_spi <= execute;
						  else
							uart_tx_sig <= start;
							send_cnt <= send_cnt + 1;
						  end if;
                end case;
            else
                send_cnt <= 0;
            end if;
        end if;
	end process spi_proc;
end spiMaster_arc;
