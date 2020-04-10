library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

entity top_module is
	port (
		i_Clk : in std_logic;
		i_Switch : in std_logic;
		
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
	
	-- Clock signals
	signal w_Clkfx_Out : std_logic;
	signal w_Clkin_Ibufg_Out : std_logic;
	signal w_Clk0_Out : std_logic;
	signal w_VGA_Clk_Enable : std_logic;
	signal w_Clk_Div : std_logic_vector(1 downto 0) := "00";
	signal w_Reset : std_logic;
	
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

begin
	----------------------------------------------
	------ 100MHz CLOCK GENERATOR INSTANCE -------
	----------------------------------------------
	w_Reset <= not i_Switch;
	Inst_clock_inst: clock_inst PORT MAP(
		CLKIN_IN => i_Clk,
		RST_IN => w_Reset,
		CLKFX_OUT => w_Clkfx_Out,
		CLKIN_IBUFG_OUT => w_Clkin_Ibufg_Out,
		CLK0_OUT => w_Clk0_Out
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
	--------------- OUTPUTS WRITE ----------------
	----------------------------------------------
	o_VGA_HSync <= w_VGA_HSync_Porch;
	o_VGA_VSync <= w_VGA_VSync_Porch;
	o_VGA_Red <= w_VGA_Red;
	o_VGA_Grn <= w_VGA_Grn;
	o_VGA_Blu <= w_VGA_Blu;
	
	-- simulation purposes
	--o_Clkfx_Out <= w_Clkfx_Out;
	--o_VGA_VSync_wo_Porch <= w_VGA_VSync;
	--o_VGA_HSync_wo_Porch <= w_VGA_HSync;
	--o_VGA_Clk_Enable <= w_VGA_Clk_Enable;
	--o_X_Pixel <= w_X_Pixel;
	--o_Y_Pixel <= w_Y_Pixel;
	
end Behavioral;

