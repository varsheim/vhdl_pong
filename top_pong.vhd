library IEEE;
use IEEE.STD_LOGIC_1164.ALL;


entity top_pong is
	port (
		i_Clk : in std_logic; -- 100MHz
		i_Clk_En : in std_logic; -- 25MHz clock enable
		i_X_Pixel : in std_logic_vector(9 downto 0);
		i_Y_Pixel : in std_logic_vector(9 downto 0);
		i_Control : in std_logic_vector(4 downto 0);
		o_Red : out std_logic_vector(2 downto 0);
		o_Grn : out std_logic_vector(2 downto 0);
		o_Blu : out std_logic_vector(1 downto 0);
		o_Score_A : out std_logic_vector(3 downto 0);
		o_Score_B : out std_logic_vector(3 downto 0);
		o_Pixel_On : out std_logic
	);
end top_pong;

architecture Behavioral of top_pong is
	-- PONG CONSTANTS
	constant c_PADDLE_WIDTH : integer := 10;
	constant c_PADDLE_LENGTH : integer := 100;
	constant c_BALL_SIZE : integer := 8;
	constant c_MAX_SCORE : integer := 9;
	constant c_PADDLE_LEFT_X_POS : integer := 10;
	constant c_PADDLE_RIGHT_X_POS : integer := 618;
	
	signal w_Paddle_L_Red, w_Paddle_R_Red, w_Ball_Red : std_logic_vector(2 downto 0);
	signal w_Paddle_L_Grn, w_Paddle_R_Grn, w_Ball_Grn : std_logic_vector(2 downto 0);
	signal w_Paddle_L_Blu, w_Paddle_R_Blu, w_Ball_Blu : std_logic_vector(1 downto 0);
	signal w_Paddle_L_Pixel_On, w_Paddle_R_Pixel_On, w_Ball_Pixel_On : std_logic;
	
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
	
begin
	----------------------------------------------
	---------------- PROCESS ---------------------
	----------------------------------------------
	inst_pong_process : entity work.pong_process
	generic map (
		g_PADDLE_WIDTH => c_PADDLE_WIDTH,
		g_PADDLE_LENGTH => c_PADDLE_LENGTH,
		g_BALL_SIZE => c_BALL_SIZE,
		g_MAX_SCORE => c_MAX_SCORE,
		g_PADDLE_LEFT_X_POS => c_PADDLE_LEFT_X_POS,
		g_PADDLE_RIGHT_X_POS => c_PADDLE_RIGHT_X_POS
	)
	port map (
		i_Clk => i_Clk,
		i_Control => i_Control,
		o_Score_A => o_Score_A,
		o_Score_B => o_Score_B,
		o_X_Ball_Start => w_X_Ball_Start,
		o_X_Ball_End => w_X_Ball_End,
		o_Y_Ball_Start => w_Y_Ball_Start,
		o_Y_Ball_End => w_Y_Ball_End,
		o_X_Paddle_L_Start => w_X_Paddle_L_Start,
		o_X_Paddle_L_End => w_X_Paddle_L_End,
		o_Y_Paddle_L_Start => w_Y_Paddle_L_Start,
		o_Y_Paddle_L_End => w_Y_Paddle_L_End,
		o_X_Paddle_R_Start => w_X_Paddle_R_Start,
		o_X_Paddle_R_End => w_X_Paddle_R_End,
		o_Y_Paddle_R_Start => w_Y_Paddle_R_Start,
		o_Y_Paddle_R_End => w_Y_Paddle_R_End
	);
	
	----------------------------------------------
	---------------- PADDLE 1 --------------------
	----------------------------------------------
	inst_pong_paddle_left : entity work.pong_paddle
	port map (
		i_X_Paddle_Start => w_X_Paddle_L_Start,
		i_Y_Paddle_Start => w_Y_Paddle_L_Start,
		i_X_Paddle_End => w_X_Paddle_L_End,
		i_Y_Paddle_End => w_Y_Paddle_L_End,
		i_X_Pixel => i_X_Pixel,
		i_Y_Pixel => i_Y_Pixel,
		o_Red => w_Paddle_L_Red,
		o_Grn => w_Paddle_L_Grn,
		o_Blu => w_Paddle_L_Blu,
		o_Pixel_On => w_Paddle_L_Pixel_On
	);
	
	----------------------------------------------
	---------------- PADDLE 2 --------------------
	----------------------------------------------
	inst_pong_paddle_right : entity work.pong_paddle
	port map (
		i_X_Paddle_Start => w_X_Paddle_R_Start,
		i_Y_Paddle_Start => w_Y_Paddle_R_Start,
		i_X_Paddle_End => w_X_Paddle_R_End,
		i_Y_Paddle_End => w_Y_Paddle_R_End,
		i_X_Pixel => i_X_Pixel,
		i_Y_Pixel => i_Y_Pixel,
		o_Red => w_Paddle_R_Red,
		o_Grn => w_Paddle_R_Grn,
		o_Blu => w_Paddle_R_Blu,
		o_Pixel_On => w_Paddle_R_Pixel_On
	);
	
	----------------------------------------------
	------------------ BALL ----------------------
	----------------------------------------------
	inst_pong_ball : entity work.pong_ball
	port map (
		i_X_Pixel => i_X_Pixel,
		i_Y_Pixel => i_Y_Pixel,
		i_X_Ball_Start => w_X_Ball_Start,
		i_X_Ball_End => w_X_Ball_End,
		i_Y_Ball_Start => w_Y_Ball_Start,
		i_Y_Ball_End => w_Y_Ball_End,
		o_Red => w_Ball_Red,
		o_Grn => w_Ball_Grn,
		o_Blu => w_Ball_Blu,
		o_Pixel_On => w_Ball_Pixel_On
	);
	
	----------------------------------------------
	--------------- OBJECTS MUX ------------------
	----------------------------------------------
	p_Objects_VGA_Mux : process (w_Paddle_L_Pixel_On, w_Paddle_R_Pixel_On, w_Ball_Pixel_On) is
	begin
		if w_Paddle_L_Pixel_On = '1' then
			o_Red <= w_Paddle_L_Red;
			o_Grn <= w_Paddle_L_Grn;
			o_Blu <= w_Paddle_L_Blu;
		elsif w_Paddle_R_Pixel_On = '1' then
			o_Red <= w_Paddle_R_Red;
			o_Grn <= w_Paddle_R_Grn;
			o_Blu <= w_Paddle_R_Blu;
		elsif w_Ball_Pixel_On = '1' then
			o_Red <= w_Ball_Red;
			o_Grn <= w_Ball_Grn;
			o_Blu <= w_Ball_Blu;
		else
			o_Red <= "000";
			o_Grn <= "000";
			o_Blu <= "00";
		end if;
	end process p_Objects_VGA_Mux;
	
	o_Pixel_On <= '1' when w_Paddle_L_Pixel_On = '1' or w_Paddle_R_Pixel_On = '1' or w_Ball_Pixel_On = '1' else '0';
end Behavioral;
