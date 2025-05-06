----------------------------------------------------------------------------------
-- Company: USAF Academy, ECE 281
-- Engineer: C3C Bruno Graziao
-- 
-- Create Date: 02/24/2025 10:41:21 AM
-- Design Name: 
-- Module Name: sevenseg_decoder - Behavioral
-- Project Name: Lab 2 - Seven segment display 
-- Target Devices: Basys3
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: IEEE.STD_LOGIC_1164.ALL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity sevenseg_decoder is
  Port ( i_Hex   : in  STD_LOGIC_VECTOR (3 downto 0);
         o_seg_n : out STD_LOGIC_VECTOR (6 downto 0)
  );
end sevenseg_decoder;

architecture Behavioral of sevenseg_decoder is

  signal seg_p_rev : STD_LOGIC_VECTOR (6 downto 0);

begin 
-- get truth table values for readability
-- called ".._p_rev" because since it is original from the truth table,
-- which is inverted and reversed from what Basys would take  
with i_Hex select
  seg_p_rev <= "1111110" when "0000", -- 0
               "0110000" when "0001", -- 1
               "1101101" when "0010", -- 2
               "1111001" when "0011", -- 3
               "0110011" when "0100", -- 4
               "1011011" when "0101", -- 5
               "1011111" when "0110", -- 6
               "1110000" when "0111", -- 7
               "1111111" when "1000", -- 8
               "1110011" when "1001", -- 9
               "1110111" when "1010", -- A
               "0011111" when "1011", -- B
	       "0001101" when "1100", -- C
	       "0111101" when "1101", -- D
	       "1001111" when "1110", -- E
	       "1000111" when "1111", -- F
	       "0000000" when others; -- default

  -- reverse and invert bits (active low) for Basys3 compatibility
  o_seg_n(0) <= not seg_p_rev(6);
  o_seg_n(1) <= not seg_p_rev(5);
  o_seg_n(2) <= not seg_p_rev(4);
  o_seg_n(3) <= not seg_p_rev(3);
  o_seg_n(4) <= not seg_p_rev(2);
  o_seg_n(5) <= not seg_p_rev(1);
  o_seg_n(6) <= not seg_p_rev(0);

end Behavioral;
