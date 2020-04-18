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
		g_PADDLE_RIGHT_X_POS : integer
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
		o_Ball_Flashing : out std_logic;
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
	constant c_REFRESH_RATE_DIVIDER : integer := 1000000; -- adjust for slowe/faster main process SM
	constant c_BALL_FLASHING_RATE_DIVIDER : integer := 49999999; -- half a second for a 100MHz clock
	constant c_MOVE_BALL_X_MAX_RATE : integer := 2100000;
	constant c_MOVE_BALL_Y_MAX_RATE : integer := 2100000;
	constant c_MOVE_PADDLE_Y_MAX_RATE : integer := 250000;
	constant c_Y_PADDLE_L_START_POS : integer := 50;
	constant c_Y_PADDLE_R_START_POS : integer := 200;
	constant c_X_BALL_START_POS : integer := 319 - g_BALL_SIZE / 2; -- centre of the screen
	constant c_Y_BALL_START_POS : integer := 239 - g_BALL_SIZE / 2;
	constant c_PADDLE_LENGTH_HALF : integer := g_PADDLE_LENGTH / 2;
	constant c_PADDLE_LENGTH_QUARTER : integer := g_PADDLE_LENGTH / 4;
	constant c_PADDLE_LENGTH_EIGTH : integer := g_PADDLE_LENGTH / 8;
	constant c_BALL_SIZE_HALF : integer := g_BALL_SIZE / 2;
	
	type Rom_Ball_Velocity_Rate is array(4 downto 0) of integer;
	constant c_MOVE_BALL_X_RATES : Rom_Ball_Velocity_Rate := (
	-- from slowest
	2100000,
	1000000,
	400000,
	340000,
	300000);
	constant c_MOVE_BALL_Y_RATES : Rom_Ball_Velocity_Rate := (
	-- from fastest, with constant complete xy velocity
	290076,
	300000,
	413057,
	652955,
	1000000);
	
	type Ball_X_Dir_Type is (s_Idle, s_Left, s_Right);
	signal sm_Ball_X_Dir : Ball_X_Dir_Type := s_Idle;
	
	type Ball_Y_Dir_Type is (s_Idle, s_Up, s_Down);
	signal sm_Ball_Y_Dir : Ball_Y_Dir_Type := s_Idle;
	
	type Pong_Game_Status_Type is (s_Start_Wait, s_Play, S_End_Wait);
	signal sm_Pong_Game_Status : Pong_Game_Status_Type := s_Start_Wait;
	
	signal w_X_Ball_Pos : std_logic_vector(9 downto 0);
	signal w_Y_Ball_Pos : std_logic_vector(8 downto 0);
	signal w_Rate_Cnt : integer range 0 to c_REFRESH_RATE_DIVIDER;
	
	signal r_Move_Ball_X_Rate : integer range 0 to c_MOVE_BALL_X_MAX_RATE := c_MOVE_BALL_X_MAX_RATE;
	signal r_Move_Ball_Y_Rate : integer range 0 to c_MOVE_BALL_Y_MAX_RATE := c_MOVE_BALL_Y_MAX_RATE;
	signal r_Move_Ball_XY_Rom_Num : integer range 0 to 4;
	signal w_Move_Ball_X_Clk_Cnt : integer range 0 to c_MOVE_BALL_X_MAX_RATE;
	signal w_Move_Ball_Y_Clk_Cnt : integer range 0 to c_MOVE_BALL_Y_MAX_RATE;
	signal w_Move_Paddle_Y_Clk_Cnt : integer range 0 to c_MOVE_PADDLE_Y_MAX_RATE;
	signal r_Ball_Flashing_Cnt : integer range 0 to c_BALL_FLASHING_RATE_DIVIDER;
	signal w_Clock_En : std_logic := '0';
	signal w_Move_Ball_X_Clk_En : std_logic := '0';
	signal w_Move_Ball_Y_Clk_En : std_logic := '0';
	signal w_Move_Paddle_Y_Clk_En : std_logic := '0';
	signal r_Ball_Flashing_On : std_logic := '0';
	signal r_Ball_Flashing : std_logic := '0';
	
	signal w_Score_A : std_logic_vector (3 downto 0) := "0000";
	signal w_Score_B : std_logic_vector (3 downto 0) := "0000";
	
	signal w_X_Ball_Start : std_logic_vector(9 downto 0);
	signal w_X_Ball_End : std_logic_vector(9 downto 0);
	signal w_Y_Ball_Start : std_logic_vector(8 downto 0);
	signal w_Y_Ball_End : std_logic_vector(8 downto 0);
	
	signal w_X_Paddle_L_Start : std_logic_vector(9 downto 0);
	signal w_X_Paddle_L_End : std_logic_vector(9 downto 0);
	signal w_Y_Paddle_L_Start : std_logic_vector(8 downto 0);
	signal w_Y_Paddle_L_End : std_logic_vector(8 downto 0);

	signal w_X_Paddle_R_Start : std_logic_vector(9 downto 0);
	signal w_X_Paddle_R_End : std_logic_vector(9 downto 0);
	signal w_Y_Paddle_R_Start : std_logic_vector(8 downto 0);
	signal w_Y_Paddle_R_End : std_logic_vector(8 downto 0);
	
	signal r_Play_Active : std_logic := '1';
	signal r_Ball_Hit_R : std_logic := '0';
	signal r_Ball_Hit_L : std_logic := '0';
	signal r_Ball_Hit_R_Ack : std_logic := '0';
	signal r_Ball_Hit_L_Ack : std_logic := '0';
	signal r_Ball_Hit_Paddle_Low : std_logic := '0';
	signal r_Ball_Hit_Paddle : std_logic := '0';
	signal r_Ball_Hit_Paddle_Ack : std_logic := '0';	

	
begin
	
	w_X_Ball_Start <= w_X_Ball_Pos;
	w_X_Ball_End <= w_X_Ball_Pos + std_logic_vector(to_unsigned(g_BALL_SIZE, w_X_Ball_End'length));
	w_Y_Ball_Start <= w_Y_Ball_Pos;
	w_Y_Ball_End <= w_Y_Ball_Pos + std_logic_vector(to_unsigned(g_BALL_SIZE, w_Y_Ball_End'length));
	
	inst_move_paddle_l : entity work.pong_move_paddle
	generic map (
		g_Y_PADDLE_START_POS => c_Y_PADDLE_L_START_POS,
		g_X_PADDLE_POS => g_PADDLE_LEFT_X_POS,
		g_PADDLE_WIDTH => g_PADDLE_WIDTH,
		g_PADDLE_LENGTH => g_PADDLE_LENGTH
	)
	port map (
		i_Clk => i_Clk,
		i_Clock_En => w_Move_Paddle_Y_Clk_En,
		i_Switch_Up => i_Control(0),
		i_Switch_Down => i_Control(1),
		o_X_Paddle_Start => w_X_Paddle_L_Start,
		o_X_Paddle_End => w_X_Paddle_L_End,
		o_Y_Paddle_Start => w_Y_Paddle_L_Start,
		o_Y_Paddle_End => w_Y_Paddle_L_End
	);
	
	inst_move_paddle_r : entity work.pong_move_paddle
	generic map (
		g_Y_PADDLE_START_POS => c_Y_PADDLE_R_START_POS,
		g_X_PADDLE_POS => g_PADDLE_RIGHT_X_POS,
		g_PADDLE_WIDTH => g_PADDLE_WIDTH,
		g_PADDLE_LENGTH => g_PADDLE_LENGTH
	)
	port map (
		i_Clk => i_Clk,
		i_Clock_En => w_Move_Paddle_Y_Clk_En,
		i_Switch_Up => i_Control(3),
		i_Switch_Down => i_Control(4),
		o_X_Paddle_Start => w_X_Paddle_R_Start,
		o_X_Paddle_End => w_X_Paddle_R_End,
		o_Y_Paddle_Start => w_Y_Paddle_R_Start,
		o_Y_Paddle_End => w_Y_Paddle_R_End
	);
	
	p_Clock_Divider : process (i_Clk) is
	begin
	-- 100MHz clock in
		if rising_edge(i_Clk) then
			if w_Rate_Cnt = c_REFRESH_RATE_DIVIDER then
				w_Rate_Cnt <= 0;
				w_Clock_En <= '1';
			else
				w_Rate_Cnt <= w_Rate_Cnt + 1;
				w_Clock_En <= '0';
			end if;
			
			if w_Move_Ball_X_Clk_Cnt >= r_Move_Ball_X_Rate then
				w_Move_Ball_X_Clk_Cnt <= 0;
				w_Move_Ball_X_Clk_En <= '1';
			else
				w_Move_Ball_X_Clk_Cnt <= w_Move_Ball_X_Clk_Cnt + 1;
				w_Move_Ball_X_Clk_En <= '0';
			end if;
			
			if w_Move_Ball_Y_Clk_Cnt >= r_Move_Ball_Y_Rate then
				w_Move_Ball_Y_Clk_Cnt <= 0;
				w_Move_Ball_Y_Clk_En <= '1';
			else
				w_Move_Ball_Y_Clk_Cnt <= w_Move_Ball_Y_Clk_Cnt + 1;
				w_Move_Ball_Y_Clk_En <= '0';
			end if;
			
			if w_Move_Paddle_Y_Clk_Cnt >= c_MOVE_PADDLE_Y_MAX_RATE then
				w_Move_Paddle_Y_Clk_Cnt <= 0;
				w_Move_Paddle_Y_Clk_En <= '1';
			else
				w_Move_Paddle_Y_Clk_Cnt <= w_Move_Paddle_Y_Clk_Cnt + 1;
				w_Move_Paddle_Y_Clk_En <= '0';
			end if;
			
			-- Ball flashing 50 %
			if r_Ball_Flashing_Cnt >= c_BALL_FLASHING_RATE_DIVIDER then
				r_Ball_Flashing_Cnt <= 0;
				r_Ball_Flashing <= not r_Ball_Flashing;
			else
				r_Ball_Flashing_Cnt <= r_Ball_Flashing_Cnt + 1;
			end if;
		end if;
	end process p_Clock_Divider;
	
	p_Game : process (i_Clk) is
	begin
		if rising_edge(i_Clk) then
			if w_Clock_En = '1' then
				case sm_Pong_Game_Status is
					when s_Start_Wait =>
						r_Ball_Flashing_On <= '1';
						r_Play_Active <= '0';
						if i_Control(2) = '1' then
							sm_Pong_Game_Status <= s_Play;
						else
							sm_Pong_Game_Status <= s_Start_Wait;
						end if;
					when s_Play =>
						r_Ball_Flashing_On <= '0';
						r_Play_Active <= '1';
						-- jesli dostane sygnal ze pilka wpadla to przejdz do start_wait
						if r_Ball_Hit_L /= r_Ball_Hit_L_Ack then
							r_Ball_Hit_L_Ack <= not r_Ball_Hit_L_Ack;
							if w_Score_B = "1001" then
								sm_Pong_Game_Status <= s_End_Wait;
							else
								w_Score_B <= w_Score_B + 1;
								sm_Pong_Game_Status <= s_Start_Wait;
							end if;
							
						elsif r_Ball_Hit_R /= r_Ball_Hit_R_Ack then
							r_Ball_Hit_R_Ack <= not r_Ball_Hit_R_Ack;
							if w_Score_A = "1001" then
								sm_Pong_Game_Status <= s_End_Wait;
							else
								w_Score_A <= w_Score_A + 1;
								sm_Pong_Game_Status <= s_Start_Wait;
							end if;
							
						else
							sm_Pong_Game_Status <= s_Play;
						end if;
						
					when s_End_Wait =>
						r_Ball_Flashing_On <= '1';
						r_Play_Active <= '0';
						w_Score_A <= "0000";
						w_Score_B <= "0000";
						if i_Control(2) = '1' then
							sm_Pong_Game_Status <= s_Play;
						else
							sm_Pong_Game_Status <= s_End_Wait;
						end if;
					end case;
			end if;
		end if;
	end process p_Game;
	
	
	p_Move_Ball_X : process (i_Clk) is
	begin
		if rising_edge(i_Clk) then
			if w_Move_Ball_X_Clk_En = '1' then
				if r_Play_Active = '1' then
					case sm_Ball_X_Dir is
						when s_Idle =>
							sm_Ball_X_Dir <= s_Right;
							
							-- assign default xy velocities
						when s_Left =>
							-- ruch w lewo
							if w_X_Ball_Start = w_X_Paddle_L_End + 1 and w_Y_Ball_End > w_Y_Paddle_L_Start and w_Y_Ball_Start < w_Y_Paddle_L_End then
								sm_Ball_X_Dir <= s_Right;
								r_Ball_Hit_Paddle <= not r_Ball_Hit_Paddle;
								if w_Y_Ball_End < (w_Y_Paddle_L_Start + c_PADDLE_LENGTH_EIGTH) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 4;
								elsif w_Y_Ball_End < (w_Y_Paddle_L_Start + c_PADDLE_LENGTH_QUARTER) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 3;
								elsif w_Y_Ball_End < (w_Y_Paddle_L_Start + c_PADDLE_LENGTH_HALF - c_PADDLE_LENGTH_EIGTH) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 2;
								elsif w_Y_Ball_End < (w_Y_Paddle_L_Start + c_PADDLE_LENGTH_HALF) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 1;
								elsif (w_Y_Ball_Start + c_BALL_SIZE_HALF) < (w_Y_Paddle_L_Start + c_PADDLE_LENGTH_HALF) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 0;
								elsif w_Y_Ball_Start > (w_Y_Paddle_L_End - c_PADDLE_LENGTH_EIGTH) then
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 4;
								elsif w_Y_Ball_Start > (w_Y_Paddle_L_End - c_PADDLE_LENGTH_QUARTER) then
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 3;
								elsif w_Y_Ball_Start > (w_Y_Paddle_L_End - c_PADDLE_LENGTH_HALF + c_PADDLE_LENGTH_EIGTH) then
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 2;
								elsif w_Y_Ball_Start > (w_Y_Paddle_L_End - c_PADDLE_LENGTH_HALF) then
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 1;
								else
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 0;
								end if;
							elsif w_X_Ball_Start = 0 then
								r_Ball_Hit_L <= not r_Ball_Hit_L;
								sm_Ball_X_Dir <= s_Right;
							else
								w_X_Ball_Pos <= w_X_Ball_Pos - 1;
								sm_Ball_X_Dir <= s_Left;
							end if;
							
						when s_Right =>
							-- right movement
							if w_X_Ball_End = w_X_Paddle_R_Start - 1 and w_Y_Ball_End > w_Y_Paddle_R_Start and w_Y_Ball_Start < w_Y_Paddle_R_End then
								sm_Ball_X_Dir <= s_Left;
								r_Ball_Hit_Paddle <= not r_Ball_Hit_Paddle;
								if w_Y_Ball_End < (w_Y_Paddle_R_Start + c_PADDLE_LENGTH_EIGTH) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 4;
								elsif w_Y_Ball_End < (w_Y_Paddle_R_Start + c_PADDLE_LENGTH_QUARTER) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 3;
								elsif w_Y_Ball_End < (w_Y_Paddle_R_Start + c_PADDLE_LENGTH_HALF - c_PADDLE_LENGTH_EIGTH) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 2;
								elsif w_Y_Ball_End < (w_Y_Paddle_R_Start + c_PADDLE_LENGTH_HALF) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 1;
								elsif (w_Y_Ball_Start + c_BALL_SIZE_HALF) < (w_Y_Paddle_R_Start + c_PADDLE_LENGTH_HALF) then
									r_Ball_Hit_Paddle_Low <= '0';
									r_Move_Ball_XY_Rom_Num <= 0;
								elsif w_Y_Ball_Start > (w_Y_Paddle_R_End - c_PADDLE_LENGTH_EIGTH) then
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 4;
								elsif w_Y_Ball_Start > (w_Y_Paddle_R_End - c_PADDLE_LENGTH_QUARTER) then
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 3;
								elsif w_Y_Ball_Start > (w_Y_Paddle_R_End - c_PADDLE_LENGTH_HALF + c_PADDLE_LENGTH_EIGTH) then
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 2;
								elsif w_Y_Ball_Start > (w_Y_Paddle_R_End - c_PADDLE_LENGTH_HALF) then
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 1;
								else
									r_Ball_Hit_Paddle_Low <= '1';
									r_Move_Ball_XY_Rom_Num <= 0;
								end if;
							elsif w_X_Ball_End = 639 then
								-- Ball hit the right side
								r_Ball_Hit_R <= not r_Ball_Hit_R;
								sm_Ball_X_Dir <= s_Left;
							else
								w_X_Ball_Pos <= w_X_Ball_Pos + 1;
								sm_Ball_X_Dir <= s_Right;
							end if;
						end case;
						
					r_Move_Ball_X_Rate <= c_MOVE_BALL_X_RATES(r_Move_Ball_XY_Rom_Num);
					r_Move_Ball_Y_Rate <= c_MOVE_BALL_Y_RATES(r_Move_Ball_XY_Rom_Num);
				else
					w_X_Ball_Pos <= std_logic_vector(to_unsigned(c_X_BALL_START_POS, w_X_Ball_Pos'length));
				end if;
			end if;
		end if;
	end process p_Move_Ball_X;
	
	p_Move_Ball_Y : process (i_Clk) is
	begin
		if rising_edge(i_Clk) then
			if w_Move_Ball_Y_Clk_En = '1' then
				if r_Play_Active = '1' then
					case sm_Ball_Y_Dir is
						when s_Idle =>
							sm_Ball_Y_Dir <= s_Up;
						when s_Up =>
							-- move up
							if w_Y_Ball_Start = 0 then
								sm_Ball_Y_Dir <= s_Down;
							elsif r_Ball_Hit_Paddle /= r_Ball_Hit_Paddle_Ack and r_Ball_Hit_Paddle_Low = '1' then
								r_Ball_Hit_Paddle_Ack <= not r_Ball_Hit_Paddle_Ack;
								sm_Ball_Y_Dir <= s_Down;
							else
								w_Y_Ball_Pos <= w_Y_Ball_Pos - 1;
								sm_Ball_Y_Dir <= s_Up;
							end if;
							
						when s_Down =>
							-- move down
							if w_Y_Ball_End = 479 then
								sm_Ball_Y_Dir <= s_Up;
							elsif r_Ball_Hit_Paddle /= r_Ball_Hit_Paddle_Ack and r_Ball_Hit_Paddle_Low = '0' then
								r_Ball_Hit_Paddle_Ack <= not r_Ball_Hit_Paddle_Ack;
								sm_Ball_Y_Dir <= s_Up;
							else
								w_Y_Ball_Pos <= w_Y_Ball_Pos + 1;
								sm_Ball_Y_Dir <= s_Down;
							end if;
						end case;
				else
					w_Y_Ball_Pos <= std_logic_vector(to_unsigned(c_Y_BALL_START_POS, w_Y_Ball_Pos'length));
				end if;
			end if;
		end if;
	end process p_Move_Ball_Y;
	
	o_Score_A <= w_Score_A;
	o_Score_B <= w_Score_B;
	
	o_X_Ball_Start <= w_X_Ball_Start;
	o_X_Ball_End <= w_X_Ball_End;
	o_Y_Ball_Start <= w_Y_Ball_Start;
	o_Y_Ball_End <= w_Y_Ball_End;
	
	o_X_Paddle_L_Start <= w_X_Paddle_L_Start;
	o_X_Paddle_L_End <= w_X_Paddle_L_End;
	o_Y_Paddle_L_Start <= w_Y_Paddle_L_Start;
	o_Y_Paddle_L_End <= w_Y_Paddle_L_End;
	
	o_X_Paddle_R_Start <= w_X_Paddle_R_Start;
	o_X_Paddle_R_End <= w_X_Paddle_R_End;
	o_Y_Paddle_R_Start <= w_Y_Paddle_R_Start;
	o_Y_Paddle_R_End <= w_Y_Paddle_R_End;
	
	o_Ball_Flashing <= r_Ball_Flashing when r_Ball_Flashing_On = '1' else '1';
	
end Behavioral;