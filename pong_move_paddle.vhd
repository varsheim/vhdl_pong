library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;

entity pong_move_paddle is
	generic (
		g_Y_PADDLE_START_POS : integer;
		g_Y_PADDLE_SPEED : integer;
		g_X_PADDLE_POS : integer;
		g_PADDLE_WIDTH : integer;
		g_PADDLE_LENGTH : integer
	);
	port (
		i_Clk : in std_logic;
		i_Clock_En : in std_logic;
		i_Switch_Up : in std_logic;
		i_Switch_Down : in std_logic;
		o_X_Paddle_Start : out integer range 0 to (639 - g_PADDLE_WIDTH);
		o_X_Paddle_End : out integer range 0 to 639;
		o_Y_Paddle_Start : out integer range 0 to (479 - g_PADDLE_LENGTH);
		o_Y_Paddle_End : out integer range 0 to 479
	);
end pong_move_paddle;
	
architecture Behavioral of pong_move_paddle is
	signal w_Y_Paddle_Pos : integer range 0 to (639 - g_PADDLE_WIDTH) := g_Y_PADDLE_START_POS;
	signal w_Y_Paddle_Start : integer range 0 to (639 - g_PADDLE_WIDTH);
	signal w_Y_Paddle_End : integer range 0 to 639;
	
begin
	w_Y_Paddle_Start <= w_Y_Paddle_Pos;
	w_Y_Paddle_End <= w_Y_Paddle_Pos + g_PADDLE_LENGTH;
	
	p_Paddle_Control : process (i_Clk) is
	begin
		if rising_edge(i_Clk) then
			if i_Clock_En = '1' then
				if i_Switch_Up = '1' then
					if w_Y_Paddle_Start > 0 then
						w_Y_Paddle_Pos <= w_Y_Paddle_Pos - 1;
					end if;
				elsif i_Switch_Down = '1' then
					if w_Y_Paddle_End < 479 then
						w_Y_Paddle_Pos <= w_Y_Paddle_Pos + 1;
					end if;
				end if;
			end if;
		end if;
	end process p_Paddle_Control;

	
	o_X_Paddle_Start <= g_X_PADDLE_POS;
	o_X_Paddle_End <= g_X_PADDLE_POS + g_PADDLE_WIDTH;
	o_Y_Paddle_Start <= w_Y_Paddle_Start;
	o_Y_Paddle_End <= w_Y_Paddle_End;

end Behavioral;

