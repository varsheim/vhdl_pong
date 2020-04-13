library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use IEEE.std_logic_unsigned.all;


entity pong_process is
	generic (
		g_PADDLE_WIDTH : integer;
		g_PADDLE_LENGTH : integer;
		g_BALL_SIZE : integer;
		g_MAX_SCORE : integer;
		g_PADDLE_LEFT_X_POS : integer;
		g_PADDLE_RIGHT_X_POS : integer;
		g_BALL_SPEED : integer;
		g_PADDLE_SPEED : integer
	);
	port (
		i_Clk : in std_logic;
		i_Control : in std_logic_vector(4 downto 0);
		o_Score_A : out std_logic_vector(3 downto 0);
		o_Score_B : out std_logic_vector(3 downto 0);
		o_X_Ball_Start : out std_logic_vector(9 downto 0);
		o_X_Ball_End : out std_logic_vector(9 downto 0);
		o_Y_Ball_Start : out std_logic_vector(8 downto 0);
		o_Y_Ball_End : out std_logic_vector(8 downto 0);
		o_X_Paddle_L_Start : out std_logic_vector(9 downto 0);
		o_X_Paddle_L_End : out std_logic_vector(9 downto 0);
		o_Y_Paddle_L_Start : out std_logic_vector(8 downto 0);
		o_Y_Paddle_L_End : out std_logic_vector(8 downto 0);
		o_X_Paddle_R_Start : out std_logic_vector(9 downto 0);
		o_X_Paddle_R_End : out std_logic_vector(9 downto 0);
		o_Y_Paddle_R_Start : out std_logic_vector(8 downto 0);
		o_Y_Paddle_R_End : out std_logic_vector(8 downto 0)
	);
	
end pong_process;

architecture Behavioral of pong_process is
	constant c_REFRESH_RATE_DIVIDER : integer := 1666666; -- 100MHz / 60Hz - adjust for slower/faster animation
	constant c_Y_PADDLE_L_START_POS : integer := 50;
	constant c_Y_PADDLE_R_START_POS : integer := 200;
	constant c_X_BALL_SPEED : std_logic_vector(2 downto 0) := "011";
	constant c_Y_BALL_SPEED : std_logic_vector(2 downto 0) := "010";
	
	signal w_X_Ball_Pos : std_logic_vector(9 downto 0);
	signal w_Y_Ball_Pos : std_logic_vector(8 downto 0);
	signal w_Rate_Cnt : integer range 0 to c_REFRESH_RATE_DIVIDER;
	signal w_Clock_En : std_logic := '0';
	
	signal w_X_Ball_Start : std_logic_vector(9 downto 0);
	signal w_X_Ball_End : std_logic_vector(9 downto 0);
	signal w_Y_Ball_Start : std_logic_vector(8 downto 0);
	signal w_Y_Ball_End : std_logic_vector(8 downto 0);
	
	signal w_X_Ball_Speed : signed(3 downto 0) := "0011";
	signal w_Y_Ball_Speed : signed(3 downto 0) := "0010";
	
begin
	
	w_X_Ball_Start <= w_X_Ball_Pos;
	w_X_Ball_End <= w_X_Ball_Pos + std_logic_vector(to_unsigned(g_BALL_SIZE, w_X_Ball_End'length));
	w_Y_Ball_Start <= w_Y_Ball_Pos;
	w_Y_Ball_End <= w_Y_Ball_Pos + std_logic_vector(to_unsigned(g_BALL_SIZE, w_Y_Ball_End'length));
	
	inst_move_paddle_l : entity work.pong_move_paddle
	generic map (
		g_Y_PADDLE_START_POS => c_Y_PADDLE_L_START_POS,
		g_Y_PADDLE_SPEED => g_PADDLE_SPEED,
		g_X_PADDLE_POS => g_PADDLE_LEFT_X_POS,
		g_PADDLE_WIDTH => g_PADDLE_WIDTH,
		g_PADDLE_LENGTH => g_PADDLE_LENGTH
	)
	port map (
		i_Clk => i_Clk,
		i_Clock_En => w_Clock_En,
		i_Switch_Up => i_Control(0),
		i_Switch_Down => i_Control(1),
		o_X_Paddle_Start => o_X_Paddle_L_Start,
		o_X_Paddle_End => o_X_Paddle_L_End,
		o_Y_Paddle_Start => o_Y_Paddle_L_Start,
		o_Y_Paddle_End => o_Y_Paddle_L_End
	);
	
	inst_move_paddle_r : entity work.pong_move_paddle
	generic map (
		g_Y_PADDLE_START_POS => c_Y_PADDLE_R_START_POS,
		g_Y_PADDLE_SPEED => g_PADDLE_SPEED,
		g_X_PADDLE_POS => g_PADDLE_RIGHT_X_POS,
		g_PADDLE_WIDTH => g_PADDLE_WIDTH,
		g_PADDLE_LENGTH => g_PADDLE_LENGTH
	)
	port map (
		i_Clk => i_Clk,
		i_Clock_En => w_Clock_En,
		i_Switch_Up => i_Control(3),
		i_Switch_Down => i_Control(4),
		o_X_Paddle_Start => o_X_Paddle_R_Start,
		o_X_Paddle_End => o_X_Paddle_R_End,
		o_Y_Paddle_Start => o_Y_Paddle_R_Start,
		o_Y_Paddle_End => o_Y_Paddle_R_End
	);
	
	p_Clock_Divider : process (i_Clk) is
	begin
		if rising_edge(i_Clk) then
			if w_Rate_Cnt < c_REFRESH_RATE_DIVIDER then
				w_Rate_Cnt <= w_Rate_Cnt + 1;
				w_Clock_En <= '0';
			else
				w_Rate_Cnt <= 0;
				w_Clock_En <= '1';
			end if;
		end if;
	end process p_Clock_Divider;
	
	p_Move_Ball : process (i_Clk) is
	begin
		if rising_edge(i_Clk) then
		-- TODO implement finite state machine to control game state
		
		
			if w_Clock_En = '1' then
				
				
				-- test ball movement
				if w_X_Ball_Pos < 400 then
					w_X_Ball_Pos <= w_X_Ball_Pos + 1;
					w_Y_Ball_Pos <= w_Y_Ball_Pos + 1;
				else
					w_X_Ball_Pos <= std_logic_vector(to_unsigned(30, w_X_Ball_Pos'length));
					w_Y_Ball_Pos <= std_logic_vector(to_unsigned(30, w_Y_Ball_Pos'length));
				end if;
			
			end if;
		end if;
	end process p_Move_Ball;
	
	o_Score_A <= std_logic_vector(to_unsigned(0, o_Score_A'length));
	o_Score_B <= std_logic_vector(to_unsigned(0, o_Score_B'length));

	
	o_X_Ball_Start <= w_X_Ball_Start;
	o_X_Ball_End <= w_X_Ball_End;
	o_Y_Ball_Start <= w_Y_Ball_Start;
	o_Y_Ball_End <= w_Y_Ball_End;
	
end Behavioral;