library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_unsigned.all;
use IEEE.numeric_std.all;

entity pong_ball is
	port (
		i_X_Pixel : in std_logic_vector(9 downto 0);
		i_Y_Pixel : in std_logic_vector(9 downto 0);
		i_X_Ball_Start : in std_logic_vector(9 downto 0);
		i_X_Ball_End : in std_logic_vector(9 downto 0);
		i_Y_Ball_Start : in std_logic_vector(8 downto 0);
		i_Y_Ball_End : in std_logic_vector(8 downto 0);
		o_Red : out std_logic_vector(2 downto 0);
		o_Grn : out std_logic_vector(2 downto 0);
		o_Blu : out std_logic_vector(1 downto 0);
		o_Pixel_On : out std_logic
	);
end pong_ball;

architecture Behavioral of pong_ball is
	type rom_type is array(7 downto 0) of std_logic_vector(7 downto 0);
	-- make the fucking ball round
	constant c_BALL_ROM : rom_type := (
	"00111100",
	"01111110",
	"11111111",
	"11111111",
	"11111111",
	"11111111",
	"01111110",
	"00111100"
	);

	signal w_Square_Ball_On : std_logic;
	signal w_ROM_Addr, w_ROM_Col : std_logic_vector(2 downto 0);
	signal w_ROM_Data : std_logic_vector(7 downto 0);
	signal w_ROM_Bit : std_logic;

begin
	o_Red <= "111";
	o_Grn <= "000";
	o_Blu <= "00";
	
	w_Square_Ball_On <= '1' when i_X_Pixel >= i_X_Ball_Start and i_X_Pixel < i_X_Ball_End
									and i_Y_Pixel >= i_Y_Ball_Start and i_Y_Pixel < i_Y_Ball_End
									else '0';
									
	-- Ball graphics rom address (row)
	w_ROM_Addr <= i_Y_Pixel(2 downto 0) - i_Y_Ball_Start(2 downto 0);
	w_ROM_Col <= i_X_Pixel(2 downto 0) - i_X_Ball_Start(2 downto 0);
	w_ROM_Data <= c_BALL_ROM(to_integer(unsigned(w_ROM_Addr)));
	w_ROM_Bit <= w_ROM_Data(to_integer(unsigned(w_ROM_Col)));

	o_Pixel_On <= '1' when w_Square_Ball_On = '1' and w_ROM_Bit = '1' else '0';

end Behavioral;