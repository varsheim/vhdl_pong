library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.std_logic_unsigned.all;
 
ENTITY testbench IS
END testbench;
 
ARCHITECTURE behavior OF testbench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT top_module
    PORT(
         i_Clk : IN  std_logic;
         i_Reset : IN  std_logic;
         
			-- VGA
			o_VGA_HSync : out std_logic;
			o_VGA_VSync : out std_logic;
			o_VGA_Red : out std_logic_vector(2 downto 0);
			o_VGA_Grn : out std_logic_vector(2 downto 0);
			o_VGA_Blu : out std_logic_vector(1 downto 0);
			o_Clkfx_Out : out std_logic;
			o_VGA_Clk_Enable : out std_logic;
			o_VGA_HSync_wo_Porch : out std_logic;
			o_VGA_VSync_wo_Porch : out std_logic;
			o_X_Pixel : out std_logic_vector(9 downto 0);
			o_Y_Pixel : out std_logic_vector(9 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal i_Clk : std_logic := '0';
   signal i_Reset : std_logic := '0';

 	--Outputs
	-- VGA
	signal o_VGA_HSync : std_logic;
	signal o_VGA_VSync : std_logic;
	signal o_VGA_Red : std_logic_vector(2 downto 0);
	signal o_VGA_Grn : std_logic_vector(2 downto 0);
	signal o_VGA_Blu : std_logic_vector(1 downto 0);
	signal o_Clkfx_Out : std_logic;
	signal o_VGA_Clk_Enable : std_logic;
	signal o_VGA_HSync_wo_Porch : std_logic;
	signal o_VGA_VSync_wo_Porch : std_logic;
	signal o_X_Pixel : std_logic_vector(9 downto 0);
	signal o_Y_Pixel : std_logic_vector(9 downto 0);

   -- Clock period definitions
   constant i_Clk_period : time := 8.33 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: top_module PORT MAP (
          i_Clk => i_Clk,
          i_Reset => i_Reset,

			-- VGA
			o_VGA_HSync => o_VGA_HSync,
			o_VGA_VSync => o_VGA_VSync,
			o_VGA_Red => o_VGA_Red,
			o_VGA_Grn => o_VGA_Grn,
			o_VGA_Blu => o_VGA_Blu,
			o_Clkfx_Out => o_Clkfx_Out,
			o_VGA_Clk_Enable => o_VGA_Clk_Enable,
			o_VGA_HSync_wo_Porch => o_VGA_HSync_wo_Porch,
			o_VGA_VSync_wo_Porch => o_VGA_VSync_wo_Porch,
			o_X_Pixel => o_X_Pixel,
			o_Y_Pixel => o_Y_Pixel
        );

   -- Clock process definitions
   i_Clk_process :process
   begin
		i_Clk <= '0';
		wait for i_Clk_period/2;
		i_Clk <= '1';
		wait for i_Clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      wait for 100 ns;	

      wait for i_Clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
