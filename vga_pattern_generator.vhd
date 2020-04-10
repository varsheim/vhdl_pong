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
		i_Pattern_Number : in std_logic_vector(2 downto 0);
		o_Red : out std_logic_vector(2 downto 0);
		o_Grn : out std_logic_vector(2 downto 0);
		o_Blu : out std_logic_vector(1 downto 0);
		o_Pixel_On : out std_logic
	);
end vga_pattern_generator;

architecture Behavioral of vga_pattern_generator is
	signal w_Color : std_logic_vector(7 downto 0) := "00000000"; --- RGB color

begin
	p_pattern_pick : process (i_Pattern_Number, i_X_Pixel(4), i_Y_Pixel)
	begin
		case i_Pattern_Number is
		when "000" =>
			-- SZACHOWNICA
			case i_X_Pixel(4) is
			when '0' =>
				if i_Y_Pixel(4) = '1' then
					w_Color <= "11111111";
				else
					w_Color <= "00000000";
				end if;
			when others =>
				if i_Y_Pixel(4) = '0' then
					w_Color <= "11111111";
				else
					w_Color <= "00000000";
				end if;
			end case;
		when "001" =>
			-- CZERWONY
			w_Color <= "11100000";
		when "010" =>
			-- ZIELONY
			w_Color <= "00011100";
		when "011" =>
			-- NIEBIESKI
			w_Color <= "00000011";
		when "100" =>
			-- BIA£Y
			w_Color <= "11111111";
		when others =>
			-- FLAGA POLSKI
			if i_Y_Pixel < 240 then
				w_Color <= "11111111";
			else
				w_Color <= "11100000";
			end if;
		end case;
	end process p_pattern_pick;
	
	o_Red <= w_Color(7 downto 5);
	o_Grn <= w_Color(4 downto 2);
	o_Blu <= w_Color(1 downto 0);
	
	o_Pixel_On <= '1';
end Behavioral;

