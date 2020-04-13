library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use ieee.std_logic_unsigned.all;


entity pong_paddle is
	port (
		i_X_Paddle_Start : in std_logic_vector(9 downto 0);
		i_Y_Paddle_Start : in std_logic_vector(8 downto 0);
		i_X_Paddle_End : in std_logic_vector(9 downto 0);
		i_Y_Paddle_End : in std_logic_vector(8 downto 0);
		i_X_Pixel : in std_logic_vector(9 downto 0);
		i_Y_Pixel : in std_logic_vector(9 downto 0);
		o_Red : out std_logic_vector(2 downto 0);
		o_Grn : out std_logic_vector(2 downto 0);
		o_Blu : out std_logic_vector(1 downto 0);
		o_Pixel_On : out std_logic
	);
end pong_paddle;

architecture Behavioral of pong_paddle is

begin
	o_Red <= "111";
	o_Grn <= "111";
	o_Blu <= "11";

	o_Pixel_On <= '1' when i_X_Pixel >= i_X_Paddle_Start and
								  i_X_Pixel < i_X_Paddle_End and
								  i_Y_Pixel >= i_Y_Paddle_Start and
								  i_Y_Pixel < i_Y_Paddle_End else
								  '0';
end Behavioral;

