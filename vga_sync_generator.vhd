library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_sync_generator is
	generic (
		g_TOTAL_COLS : integer;
		g_TOTAL_ROWS : integer;
		g_ACTIVE_COLS : integer;
		g_ACTIVE_ROWS : integer;
		g_FRONT_PORCH_HORZ : integer;
		g_BACK_PORCH_HORZ : integer;
		g_FRONT_PORCH_VERT : integer;
		g_BACK_PORCH_VERT : integer
	);
	port (
		i_Clk : in  std_logic;
		i_Clk_En	: in std_logic;
		o_HSync : out std_logic;
		o_VSync : out std_logic;
		o_HSync_Porch : out std_logic;
		o_VSync_Porch : out std_logic;
		o_Col_Count : out std_logic_vector(9 downto 0);
		o_Row_Count : out std_logic_vector(9 downto 0)
	);
	 
end vga_sync_generator;

architecture Behavioral of vga_sync_generator is
	constant c_PORCH_HORZ_START : integer := g_ACTIVE_COLS + g_FRONT_PORCH_HORZ;
	constant c_PORCH_HORZ_END : integer := g_TOTAL_COLS - g_BACK_PORCH_HORZ;

	constant c_PORCH_VERT_START : integer := g_ACTIVE_ROWS + g_FRONT_PORCH_VERT;
	constant c_PORCH_VERT_END : integer := g_TOTAL_ROWS + g_BACK_PORCH_VERT;
	
	signal r_Col_Count : integer range 0 to g_TOTAL_COLS-1 := 0;
	signal r_Row_Count : integer range 0 to g_TOTAL_ROWS-1 := 0;

begin
	p_sync_gen : process (i_Clk) is
	begin
		if rising_edge(i_Clk) then
			if i_Clk_En = '1' then
				if r_Col_Count = g_TOTAL_COLS-1 then
					if r_Row_Count = g_TOTAL_ROWS-1 then
						r_Row_Count <= 0;
					else
						r_Row_Count <= r_Row_Count + 1;
					end if;
					r_Col_Count <= 0;
				else
					r_Col_Count <= r_Col_Count + 1;
				end if;
			end if;
		end if;
	end process p_sync_gen;
	
	o_HSync <= '1' when r_Col_Count < g_ACTIVE_COLS else '0';
	o_VSync <= '1' when r_Row_Count < g_ACTIVE_ROWS else '0';
	
	o_HSync_Porch <= '0' when (r_Col_Count > c_PORCH_HORZ_START - 1) and (r_Col_Count < c_PORCH_HORZ_END) else '1';
	o_VSync_Porch <= '0' when (r_Row_Count > c_PORCH_VERT_START - 1) and (r_Row_Count < c_PORCH_VERT_END) else '1';
	
	o_Col_Count <= std_logic_vector(to_unsigned(r_Col_Count, o_Col_Count'length));
	o_Row_Count <= std_logic_vector(to_unsigned(r_Row_Count, o_Row_Count'length));
end Behavioral;

