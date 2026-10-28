----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:31:51 09/20/2026 
-- Design Name: 
-- Module Name:    toeplitz_extractor - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity toeplitz_extractor is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           data_valid : in  STD_LOGIC;
           data_in : in  STD_LOGIC;
           seed_in : in  STD_LOGIC;
           data_out : out  STD_LOGIC;
           out_valid : out  STD_LOGIC);
end toeplitz_extractor;

architecture Behavioral of toeplitz_extractor is

begin


end Behavioral;

