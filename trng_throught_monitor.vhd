----------------------------------------------------------------------------------
-- Create Date:    14/11/2026 
-- Project Name:   Entropy Extractor
-- Module Name:    toeplitz_extractor
-- Target Devices: XC6SLX45 (Spartan 6)
-- Description:    Monitor of throughtput
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity trng_throughtput_monitor is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           data_ready : in  STD_LOGIC;
           bit_width : in  integer := 64;
           bits_per_sec : out  STD_LOGIC_VECTOR (31 downto 0));
end trng_throughtput_monitor;

architecture Behavioral of trng_throughtput_monitor is
	signal second_counter : integer range 0 to 100_000_000 := 0;
	signal bit_accumulator : unsigned(31 downto 0) := (others => '0');
begin

    process(clk, rst)
    begin
        if rst = '1' then
            second_counter  <= 0;
            bit_accumulator <= (others => '0');
            bits_per_sec    <= (others => '0');
        elsif rising_edge(clk) then
            -- Zliczanie bitów, gdy TRNG dostarcza dane
            if data_ready = '1' then
                bit_accumulator <= bit_accumulator + to_unsigned(64, 32); -- np. 64 bity na transakcje
            end if;

            -- Okno pomiarowe: dokladnie 1 sekunda dla zegara 100 MHz
            if second_counter = 100_000_000 - 1 then
                second_counter <= 0;
                bits_per_sec   <= std_logic_vector(bit_accumulator);
                bit_accumulator <= (others => '0'); -- reset licznika na kolejna sekunde
            else
                second_counter <= second_counter + 1;
            end if;
        end if;
    end process;

end Behavioral;

