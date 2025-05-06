----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:50:18 PM
-- Design Name: 
-- Module Name: ALU - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
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

entity ALU is
  Port(i_A      : in  STD_LOGIC_VECTOR (7 downto 0);
       i_B      : in  STD_LOGIC_VECTOR (7 downto 0);
       i_op     : in  STD_LOGIC_VECTOR (2 downto 0);
       o_result : out STD_LOGIC_VECTOR (7 downto 0);
       o_flags  : out STD_LOGIC_VECTOR (3 downto 0));
end ALU;

architecture Behavioral of ALU is

-- component declarations

component ripple_adder is
  port(A : in STD_LOGIC_VECTOR (3 downto 0);
       B : in STD_LOGIC_VECTOR (3 downto 0);
       Cin : in STD_LOGIC;
       S : out STD_LOGIC_VECTOR (3 downto 0);
       Cout : out STD_LOGIC
      );
end component ripple_adder;

-- signals

signal w_A  : STD_LOGIC_VECTOR(7 downto 0);
signal w_B  : STD_LOGIC_VECTOR(7 downto 0);
signal w_op : STD_LOGIC_VECTOR(2 downto 0);
signal w_result : STD_LOGIC_VECTOR(7 downto 0);
signal w_flags  : STD_LOGIC_VECTOR(3 downto 0);

signal w_ifsub     : STD_LOGIC; -- carry in to first if subracting
signal w_carrythru : STD_LOGIC; -- carry between 2 full adders
signal w_carryout  : STD_LOGIC; -- carry out, readability

signal w_addsubres : STD_LOGIC_VECTOR(7 downto 0); -- sol from adder

signal w_flag_N : STD_LOGIC; -- flags separate for readability
signal w_flag_C : STD_LOGIC;
signal w_flag_Z : STD_LOGIC;
signal w_flag_V : STD_LOGIC;

begin

-- port maps
ripple_1 : ripple_adder
port map(
  A    => w_A(3 downto 0), -- least sig half of A
  B    => w_B(3 downto 0),
  Cin  => w_ifsub, -- carry in Nothing to first ripple
  S    => w_addsubres(3 downto 0),
  Cout => w_carrythru);
  
ripple_2 : ripple_adder
port map(
  A    => w_A(7 downto 4), -- most sig half of A
  B    => w_B(7 downto 4),
  Cin  => w_carrythru,
  S    => w_addsubres(7 downto 4),
  Cout => w_carryout);

-- concurrent
  -- adder multiplexers for twos complement
with w_op(0) select       -- flip
  w_B <= w_B when '0',
     not w_B when others;
with w_op(0) select       -- add 1
  w_ifsub <= '0' when '0',
             '1' when others;

  -- result multiplexer: ADD, SUB, AND, OR
with w_op select
  w_result <= w_A and w_B when "010",
              w_A or  w_B when "011",
              w_addsubres when others;
              
  -- flags
w_flag_N <= w_result(7); -- MSB of res
w_flag_C <= w_carryout;  -- from second adder
w_flag_Z <= not (w_result(0)
             and w_result(1)
             and w_result(2)
             and w_result(3)
             and w_result(4)
             and w_result(5)
             and w_result(6)
             and w_result(7)); -- if all bits are 0
w_flag_V <= w_op(1) and -- that we are adding or subing AND..
          ((w_A(7) and w_B(7) and not w_result(7)) -- if mismatch in MSB operand->ans
        or (not w_A(7) and not w_B(7) and w_result(7)));

w_flags(3) <= w_flag_N;
w_flags(2) <= w_flag_C;
w_flags(1) <= w_flag_Z;
w_flags(0) <= w_flag_V;

  -- map wires to IO
w_A  <= i_A;
w_B  <= i_B;
w_op <= i_op;
o_flags  <= w_flags;
o_result <= w_result;

end Behavioral;
