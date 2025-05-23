----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2025 02:42:49 PM
-- Design Name: 
-- Module Name: controller_fsm - FSM
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

entity controller_fsm is
    Port ( i_reset : in STD_LOGIC;
           i_adv : in STD_LOGIC;
           o_cycle : out STD_LOGIC_VECTOR (3 downto 0));
end controller_fsm;

architecture FSM of controller_fsm is

signal w_cycle : STD_LOGIC_VECTOR(3 downto 0) := "0001";
signal w_cycle_next : STD_LOGIC_VECTOR(3 downto 0) := "0010";

begin
w_cycle_next <= "0001" when i_reset = '1' else
                "0000" when w_cycle = "1000" else
                "0010" when w_cycle = "0001" else
                "0100" when w_cycle = "0010" else
                "1000" when w_cycle = "0100";
                
o_cycle <= w_cycle;

state_proc : process (i_adv, i_reset)
begin
if i_reset = '1' then
  w_cycle <= "0000";  -- reset state is fl2
elsif (rising_edge(i_adv)) then
  w_cycle <= w_cycle_next; -- to next state
end if;
end process state_proc;

end FSM;
