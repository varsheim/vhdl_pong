library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

entity top_module is
	generic (
		g_CLKS_PER_UART_BIT : integer := 868     -- baud: 115200 for freq: 100MHz
	);
	port (
		i_Clk : in std_logic;
		i_Switch : in std_logic_vector(1 downto 0);
		i_UartRX : in STD_LOGIC;

		o_LED : out STD_LOGIC;
		o_UartTX : out STD_LOGIC;
		o_SegEn : out STD_LOGIC_VECTOR(2 downto 0);
		o_SegLED : out STD_LOGIC_VECTOR(7 downto 0);
		
		-- VGA
		o_VGA_HSync : out std_logic;
		o_VGA_VSync : out std_logic;
		o_VGA_Red : out std_logic_vector(2 downto 0);
		o_VGA_Grn : out std_logic_vector(2 downto 0);
		o_VGA_Blu : out std_logic_vector(1 downto 0)
		-- simulation purpose
		--o_Clkfx_Out : out std_logic;
		--o_VGA_Clk_Enable : out std_logic;
		--o_VGA_HSync_wo_Porch : out std_logic;
		--o_VGA_VSync_wo_Porch : out std_logic;
		--o_X_Pixel : out std_logic_vector(9 downto 0);
		--o_Y_Pixel : out std_logic_vector(9 downto 0)
	);
end top_module;

architecture Behavioral of top_module is
	-- Clock PLL component
	COMPONENT clock_inst
	PORT(
		CLKIN_IN : IN std_logic;
		RST_IN : IN std_logic;          
		CLKFX_OUT : OUT std_logic;
		CLKIN_IBUFG_OUT : OUT std_logic;
		CLK0_OUT : OUT std_logic
		);
	END COMPONENT;
	
	-- VGA Constants to set Frame Size
	constant c_VIDEO_WIDTH : integer := 3;
	constant c_TOTAL_COLS : integer := 800;
	constant c_TOTAL_ROWS : integer := 525;
	constant c_ACTIVE_COLS : integer := 640;
	constant c_ACTIVE_ROWS : integer := 480;
	constant c_FRONT_PORCH_HORZ : integer := 16;
	constant c_BACK_PORCH_HORZ : integer := 48;
	constant c_FRONT_PORCH_VERT : integer := 10;
	constant c_BACK_PORCH_VERT : integer := 33;
	-- 7 SEGMENT CONSTANTS
	constant c_SEGMENT_PERIOD : integer := 100000; -- 1 miliseconds
	
	-- Clock signals
	signal w_Clkfx_Out : std_logic;
	signal w_Clkin_Ibufg_Out : std_logic;
	signal w_Clk0_Out : std_logic;
	signal w_VGA_Clk_Enable : std_logic;
	signal w_Clk_Div : std_logic_vector(1 downto 0) := "00";
	signal w_Reset : std_logic := '0';
	
	-- VGA signals
	signal w_VGA_HSync : std_logic;
	signal w_VGA_VSync : std_logic;
	signal w_VGA_Red : std_logic_vector(2 downto 0);
	signal w_VGA_Grn : std_logic_vector(2 downto 0);
	signal w_VGA_Blu : std_logic_vector(1 downto 0);
	signal w_VGA_VSync_Porch : std_logic;
	signal w_VGA_HSync_Porch : std_logic;
	signal w_X_Pixel : std_logic_vector(9 downto 0);
	signal w_Y_Pixel : std_logic_vector(9 downto 0);
	signal w_Pixel_On : std_logic;
	
	-- IO signals
	signal r_LED_1 : STD_LOGIC := '0';
	signal r_Switch : STD_LOGIC_VECTOR(1 downto 0) := "00";
	signal w_Switch : STD_LOGIC_VECTOR(1 downto 0);
	
	-- BUTTON COUNTER signal
	signal r_SwitchBCHcnt : STD_LOGIC_VECTOR(11 downto 0) := "000000000000";
	
	-- SIGNALS 7 segments display
	signal r_CurrentSegment : STD_LOGIC_VECTOR(2 downto 0) := "001";
	signal r_SegmentTimer : integer range 0 to c_SEGMENT_PERIOD := 0;
	signal r_SegmentCurrentDigit : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	
	-- UART COMMUNICATION
	signal w_RXDV : STD_LOGIC := '0';
	signal w_TXDV : STD_LOGIC;-- := '0';
	
	signal w_TXActive : STD_LOGIC := '0';
	signal w_TXSerial : STD_LOGIC := '1';
	
	signal w_RXByte : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
	signal w_TXByte : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
	
	signal r_SwitchBCHcntReceived : STD_LOGIC_VECTOR(11 downto 0) := "000000000000";
	signal r_TXDataReady : STD_LOGIC := '0';

begin
	----------------------------------------------
	------ 100MHz CLOCK GENERATOR INSTANCE -------
	----------------------------------------------
	Inst_clock_inst: clock_inst PORT MAP(
		CLKIN_IN => i_Clk,
		RST_IN => w_Reset,
		CLKFX_OUT => w_Clkfx_Out,
		CLKIN_IBUFG_OUT => w_Clkin_Ibufg_Out,
		CLK0_OUT => w_Clk0_Out
	);

	----------------------------------------------
	------ DEBOUNCE TWO SWITCHES INSTANCES -------
	----------------------------------------------
	DebounceInst1 : entity work.debounce_switch
	port map (
		i_Clk    => w_Clkfx_Out,
		i_Switch => i_Switch(0),
		o_Switch => w_Switch(0)
	);
	
	DebounceInst2 : entity work.debounce_switch
	port map (
		i_Clk    => w_Clkfx_Out,
		i_Switch => i_Switch(1),
		o_Switch => w_Switch(1)
	);
			
	----------------------------------------------
	---------- UART RX & TX INSTANCES ------------
	----------------------------------------------
	UARTRX : entity work.uart_rx
	generic map (
		g_CLKS_PER_BIT => g_CLKS_PER_UART_BIT)
	port map (
		i_Clk      => w_Clkfx_Out,
		i_RXSerial => i_UartRX,
		o_RXDV     => w_RXDV,
		o_RXByte   => w_RXByte
	);

	-- Instantiate UART TX
	UARTTX : entity work.uart_tx
	generic map (
		g_CLKS_PER_BIT => g_CLKS_PER_UART_BIT)
	port map (
		i_Clk      => w_Clkfx_Out,
		i_TXDV     => w_TXDV,
		i_TXByte   => w_TXByte,
		o_TXSerial => w_TXSerial,
		o_TXActive => w_TXActive
	);
			
	o_UartTX <= w_TXSerial when w_TXActive = '1' else '1';
	
	-- Instantiate BCH (Binary Coded Hexadecimal) to 7SEG
	BCHToSegmentInst : entity work.bch_to_segment
	port map (
		i_Digit => r_SegmentCurrentDigit,
		o_SegLED => o_SegLED
	);
		
	----------------------------------------------
	-------- VGA SYNC GENERATOR INSTANCE ---------
	----------------------------------------------
	inst_vga_sync_gen : entity work.vga_sync_generator 
	generic map (
		g_TOTAL_COLS => c_TOTAL_COLS,
		g_TOTAL_ROWS => c_TOTAL_ROWS,
		g_ACTIVE_COLS => c_ACTIVE_COLS,
		g_ACTIVE_ROWS => c_ACTIVE_ROWS,
		g_FRONT_PORCH_HORZ => c_FRONT_PORCH_HORZ,
		g_BACK_PORCH_HORZ => c_BACK_PORCH_HORZ,
		g_FRONT_PORCH_VERT => c_FRONT_PORCH_VERT,
		g_BACK_PORCH_VERT => c_BACK_PORCH_VERT
	)
	port map (
		i_Clk => w_Clkfx_Out,
		i_Clk_En => w_VGA_Clk_Enable,
		o_HSync => w_VGA_HSync,
		o_VSync => w_VGA_VSync,
		o_HSync_Porch => w_VGA_HSync_Porch,
		o_VSync_Porch => w_VGA_VSync_Porch,
		o_Col_Count => w_X_Pixel,
		o_Row_Count => w_Y_Pixel
	);
	
	----------------------------------------------
	------- VGA PATTERN GENERATOR INSTANCE -------
	----------------------------------------------
	inst_vga_pattern_gen : entity work.vga_pattern_generator 
	port map (
		i_Clk => w_Clkfx_Out,
		i_Clk_En => w_VGA_Clk_Enable,
		i_X_Pixel => w_X_Pixel,
		i_Y_Pixel => w_Y_Pixel,
		i_Pattern_Number => r_SwitchBCHcntReceived(2 downto 0),
		o_Red => w_VGA_Red,
		o_Grn => w_VGA_Grn,
		o_Blu => w_VGA_Blu,
		o_Pixel_On => w_Pixel_On
	);
	
	----------------------------------------------
	----- 100MHz clock to 25Mhz clock enable -----
	----------------------------------------------
	p_VGA_Clock : process(w_Clkfx_Out) is
	begin
		if rising_edge(w_Clkfx_Out) then
			-- count to 25MHz
			w_Clk_Div <= w_Clk_Div + 1;
			
			if w_Clk_Div = "11" then
				w_VGA_Clk_Enable <= '1';
			else
				w_VGA_Clk_Enable <= '0';
			end if;
		
		end if;
	end process p_VGA_Clock;

	----------------------------------------------
	--- HANDLE BUTTON COUNTER AND TRANSMISSION ---
	----------------------------------------------
	p_Register : process (w_Clkfx_Out) is
	begin
		if rising_edge(w_Clkfx_Out) then
			r_Switch <= not(w_Switch);
			
			-- switch 1 is released
			-- increment HEX counter
			-- send it via UART
			if r_Switch(0) = '1' and not(w_Switch(0)) = '0' then
				-- zmiana stanu LED
				r_LED_1 <= not r_LED_1;
				
				-- BCH increment
				if r_SwitchBCHcnt(3 downto 0) < 15 then
					r_SwitchBCHcnt(3 downto 0) <= r_SwitchBCHcnt(3 downto 0) + 1;
				else
					r_SwitchBCHcnt(3 downto 0) <= "0000";
					if r_SwitchBCHcnt(7 downto 4) < 15 then
						r_SwitchBCHcnt(7 downto 4) <= r_SwitchBCHcnt(7 downto 4) + 1;
					else
						r_SwitchBCHcnt(7 downto 4) <= "0000";
						if r_SwitchBCHcnt(11 downto 8) < 0 then
							r_SwitchBCHcnt(11 downto 8) <= r_SwitchBCHcnt(11 downto 8) + 1;
						else
							r_SwitchBCHcnt(11 downto 8) <= "0000";
						end if;
					end if;
				end if;
				
				-- send the youngest 8 bits of counter via UART
				r_TXDataReady <= '1';
			end if;
			
			-- switch 2 is released
			if r_Switch(1) = '1' and not(w_Switch(1)) = '0' then
				r_SwitchBCHcnt(11 downto 0) <= "000000000000";
				
				-- send the youngest 8 bits of counter via UART
				r_TXDataReady <= '1';
			end if;
			
			if r_TXDataReady = '1' then
				w_TXByte <= r_SwitchBCHcnt(7 downto 0);
				w_TXDV <= '1';
				r_TXDataReady <= '0';
			else
				w_TXDV <= '0';
			end if;
			
			-- set new data to display when it is received
			if w_RXDV = '1' then
				r_SwitchBCHcntReceived(7 downto 0) <= w_RXByte;
			end if;
			
		end if;
	end process p_Register;
	
	
	----------------------------------------------
	----- SHIFT CURRENT 7SEGMENT DISPLAY ---------
	----------------------------------------------
	p_Display : process (w_Clkfx_Out) is
	begin
		if rising_edge(w_Clkfx_Out) then
			-- activate segment for a specified time
			if r_SegmentTimer < c_SEGMENT_PERIOD - 1 then
				r_SegmentTimer <= r_SegmentTimer + 1;
			elsif r_SegmentTimer = c_SEGMENT_PERIOD - 1 then
				-- shift register
				r_CurrentSegment <= r_CurrentSegment(0) & r_CurrentSegment(2 downto 1);
				r_SegmentTimer <= 0;
			end if;
		end if;
	end process p_Display;
	
	-- multiplex every digit
	with r_CurrentSegment select
		r_SegmentCurrentDigit <= r_SwitchBCHcntReceived(3 downto 0) when "001",
										 r_SwitchBCHcntReceived(7 downto 4) when "010",
										 r_SwitchBCHcntReceived(11 downto 8) when "100",
										 "0000" when others;
	

	----------------------------------------------
	--------------- OUTPUTS WRITE ----------------
	----------------------------------------------
	o_VGA_HSync <= w_VGA_HSync_Porch;
	o_VGA_VSync <= w_VGA_VSync_Porch;
	
	o_VGA_Red <= w_VGA_Red when w_X_Pixel < 640 and w_Y_Pixel < 480 else "000";
	o_VGA_Grn <= w_VGA_Grn when w_X_Pixel < 640 and w_Y_Pixel < 480 else "000";
	o_VGA_Blu <= w_VGA_Blu when w_X_Pixel < 640 and w_Y_Pixel < 480 else "00";
	
	o_SegEn <= not(r_CurrentSegment);
	o_LED <= r_LED_1;
	-- simulation purposes
	--o_Clkfx_Out <= w_Clkfx_Out;
	--o_VGA_VSync_wo_Porch <= w_VGA_VSync;
	--o_VGA_HSync_wo_Porch <= w_VGA_HSync;
	--o_VGA_Clk_Enable <= w_VGA_Clk_Enable;
	--o_X_Pixel <= w_X_Pixel;
	--o_Y_Pixel <= w_Y_Pixel;
	
end Behavioral;

