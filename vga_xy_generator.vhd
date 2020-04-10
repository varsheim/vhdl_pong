library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity vga_xy_generator is
	Port (i_Clk : in std_logic;
			i_HSync : in std_logic;
			i_VSync : in std_logic;
			o_X_Pixel : out std_logic_vector(9 downto 0);
			o_Y_Pixel : out std_logic_vector(9 downto 0)
			);
end vga_xy_generator;

architecture Behavioral of vga_xy_generator is

begin


end Behavioral;

