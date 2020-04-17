library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity top_module is
	generic (
		g_CLKS_PER_UART_BIT : integer := 868     -- baud: 115200 for freq: 100MHz
	);
	port (
		i_Clk : in std_logic;
		i_Switch : in std_logic_vector(4 downto 0);
--		i_UartRX : in STD_LOGIC;

		o_LED : out STD_LOGIC;
--		o_UartTX : out STD_LOGIC;
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
	signal w_VGA_Clk_Enable : std_logic;
	signal w_Clk_Div : std_logic_vector(1 downto 0) := "00";
	signal w_Reset : std_logic := '0';
	
	-- VGA signals
	signal w_VGA_VSync_Porch : std_logic;
	signal w_VGA_HSync_Porch : std_logic;
	signal w_X_Pixel : std_logic_vector(9 downto 0);
	signal w_Y_Pixel : std_logic_vector(9 downto 0);
	signal w_Pixel_On : std_logic;
	
	-- IO signals
	signal r_LED_1 : STD_LOGIC := '0';
	signal w_Switch : STD_LOGIC_VECTOR(4 downto 0);
	
	-- SIGNALS 7 segments display
	signal r_CurrentSegment : STD_LOGIC_VECTOR(2 downto 0) := "001";
	signal r_SegmentTimer : integer range 0 to c_SEGMENT_PERIOD := 0;
	signal r_SegmentCurrentDigit : STD_LOGIC_VECTOR(3 downto 0) := "0000";
	
	-- UART COMMUNICATION
--	signal w_RXDV : STD_LOGIC := '0';
--	signal w_TXDV : STD_LOGIC;-- := '0';
--
--	signal w_TXActive : STD_LOGIC := '0';
--	signal w_TXSerial : STD_LOGIC := '1';
	
--	signal w_RXByte : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
--	signal w_TXByte : STD_LOGIC_VECTOR(7 downto 0) := "00000000";
--	signal r_TXDataReady : STD_LOGIC := '0';

	-- PONG SIGNALS
	signal w_VGA_Pong_Red : std_logic_vector(2 downto 0);
	signal w_VGA_Pong_Grn : std_logic_vector(2 downto 0);
	signal w_VGA_Pong_Blu : std_logic_vector(1 downto 0);
	signal w_Pixel_Pong_On : std_logic;
	signal w_Score_A : std_logic_vector(3 downto 0);
	signal w_Score_B : std_logic_vector(3 downto 0);
	
begin
	----------------------------------------------
	------ 100MHz CLOCK GENERATOR INSTANCE -------
	----------------------------------------------
	inst_clock_inst: clock_inst PORT MAP(
		CLKIN_IN => i_Clk,
		RST_IN => w_Reset,
		CLKFX_OUT => w_Clkfx_Out,
		CLKIN_IBUFG_OUT => open,
		CLK0_OUT => open
	);

	----------------------------------------------
	------ DEBOUNCE FIVE SWITCHES INSTANCES -------
	----------------------------------------------
	inst_debounce_switch0 : entity work.debounce_switch
	port map (
		i_Clk    => w_Clkfx_Out,
		i_Switch => i_Switch(0),
		o_Switch => w_Switch(0)
	);
	
	inst_debounce_switch1 : entity work.debounce_switch
	port map (
		i_Clk    => w_Clkfx_Out,
		i_Switch => i_Switch(1),
		o_Switch => w_Switch(1)
	);
	
	inst_debounce_switch2 : entity work.debounce_switch
	port map (
		i_Clk    => w_Clkfx_Out,
		i_Switch => i_Switch(2),
		o_Switch => w_Switch(2)
	);
	
	inst_debounce_switch3 : entity work.debounce_switch
	port map (
		i_Clk    => w_Clkfx_Out,
		i_Switch => i_Switch(3),
		o_Switch => w_Switch(3)
	);
	
	inst_debounce_switch4 : entity work.debounce_switch
	port map (
		i_Clk    => w_Clkfx_Out,
		i_Switch => i_Switch(4),
		o_Switch => w_Switch(4)
	);
			
	----------------------------------------------
	---------- UART RX & TX INSTANCES ------------
	----------------------------------------------
	-- UART RX
--	UARTRX : entity work.uart_rx
--	generic map (
--		g_CLKS_PER_BIT => g_CLKS_PER_UART_BIT)
--	port map (
--		i_Clk      => w_Clkfx_Out,
--		i_RXSerial => i_UartRX,
--		o_RXDV     => w_RXDV,
--		o_RXByte   => w_RXByte
--	);

	-- UART TX
--	UARTTX : entity work.uart_tx
--	generic map (
--		g_CLKS_PER_BIT => g_CLKS_PER_UART_BIT)
--	port map (
--		i_Clk      => w_Clkfx_Out,
--		i_TXDV     => w_TXDV,
--		i_TXByte   => w_TXByte,
--		o_TXSerial => w_TXSerial,
--		o_TXActive => w_TXActive
--	);
--			
--	o_UartTX <= w_TXSerial when w_TXActive = '1' else '1';
	
	----------------------------------------------
	--------- HEX TO 7 SEGMENT DISPLAY -----------
	----------------------------------------------
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
		o_HSync => open,
		o_VSync => open,
		o_HSync_Porch => w_VGA_HSync_Porch,
		o_VSync_Porch => w_VGA_VSync_Porch,
		o_Col_Count => w_X_Pixel,
		o_Row_Count => w_Y_Pixel
	);
	
	----------------------------------------------
	------------------ PONG ----------------------
	----------------------------------------------
	inst_pong : entity work.top_pong
	port map (
		i_Clk => w_Clkfx_Out, -- 100MHz
		i_Clk_En => w_VGA_Clk_Enable, -- 25MHz clock enable
		i_X_Pixel => w_X_Pixel,
		i_Y_Pixel => w_Y_Pixel,
		i_Control => not(w_Switch), -- Switches are normally '1'
		o_Red => w_VGA_Pong_Red,
		o_Grn => w_VGA_Pong_Grn,
		o_Blu => w_VGA_Pong_Blu,
		o_Score_A => w_Score_A,
		o_Score_B => w_Score_B,
		o_Pixel_On => w_Pixel_Pong_On
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
	---------- HANDLE UART TRANSMISSION ----------
	----------------------------------------------
--	p_Register : process (w_Clkfx_Out) is
--	begin
--		if rising_edge(w_Clkfx_Out) then
--			-- Receive example
--			if w_RXDV = '1' then
--				r_Score(7 downto 0) <= w_RXByte;
--			end if;
--		end if;
--	end process p_Register;
	
	
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
		r_SegmentCurrentDigit <= w_Score_B when "001",
										 w_Score_A when "100",
										 "0000" when others;
	

	----------------------------------------------
	--------------- OUTPUTS WRITE ----------------
	----------------------------------------------
	o_VGA_HSync <= w_VGA_HSync_Porch;
	o_VGA_VSync <= w_VGA_VSync_Porch;
	
	o_VGA_Red <= w_VGA_Pong_Red when w_X_Pixel < 640 and w_Y_Pixel < 480 else "000";
	o_VGA_Grn <= w_VGA_Pong_Grn when w_X_Pixel < 640 and w_Y_Pixel < 480 else "000";
	o_VGA_Blu <= w_VGA_Pong_Blu when w_X_Pixel < 640 and w_Y_Pixel < 480 else "00";
	
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

