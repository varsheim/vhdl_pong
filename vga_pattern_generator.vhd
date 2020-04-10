library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;

entity vga_pattern_generator is
	port (
		i_Clk : in std_logic;
		i_Clk_En : in std_logic;
		i_X_Pixel : in std_logic_vector(9 downto 0);
		i_Y_Pixel : in std_logic_vector(9 downto 0);
		o_Red : out std_logic_vector(2 downto 0);
		o_Grn : out std_logic_vector(2 downto 0);
		o_Blu : out std_logic_vector(1 downto 0);
		o_Pixel_On : out std_logic
	);
end vga_pattern_generator;

architecture Behavioral of vga_pattern_generator is
	signal w_Color : std_logic_vector(7 downto 0) := "00000000"; --- RGB color

begin
	w_Color <= "11111111" when i_X_Pixel < 100 or
							  (i_X_Pixel >= 200 and i_X_Pixel < 300) or
							  (i_X_Pixel >= 400 and i_X_Pixel < 500) or
							  (i_X_Pixel >= 600 and i_X_Pixel < 640) else "00000000";
	
	o_Red <= w_Color(7 downto 5);
	o_Grn <= w_Color(4 downto 2);
	o_Blu <= w_Color(1 downto 0);
	
	o_Pixel_On <= '1';
end Behavioral;

