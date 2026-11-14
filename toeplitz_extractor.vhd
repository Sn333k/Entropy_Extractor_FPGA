----------------------------------------------------------------------------------
-- Create Date:    20/09/2026 
-- Project Name:   Entropy Extractor
-- Module Name:    toeplitz_extractor
-- Target Devices: XC6SLX45 (Spartan 6)
-- Description:    Toeplitz matrix in ROM
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity toeplitz_extractor is
    generic (
        IN_WIDTH  : integer := 64; -- Liczba wejsciowych bitów surowej entropii (n)
        OUT_WIDTH : integer := 32  -- Liczba wyjsciowych bitów po ekstrakcji (m)
    );
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;

        -- Interfejs wejsciowy
        s_data    : in  std_logic_vector(IN_WIDTH - 1 downto 0);
        s_valid   : in  std_logic;
        s_ready   : out std_logic;

        -- Interfejs wyjsciowy
        m_data    : out std_logic_vector(OUT_WIDTH - 1 downto 0);
        m_valid   : out std_logic;
        m_ready   : in  std_logic
    );
end toeplitz_extractor;

architecture Behavioral of toeplitz_extractor is

    type toeplitz_matrix_type is array (0 to OUT_WIDTH - 1) of std_logic_vector(IN_WIDTH - 1 downto 0);
    
    -- Macierz Toeplitza
    constant T_MATRIX : toeplitz_matrix_type := (
        0  => "1011010011010011101101001101001110110100110100111011010011010011",
        1  => "1101101001101001110110100110100111011010011010011101101001101001",
        2  => "0110110100110100111011010011010011101101001101001110110100110100",
        3  => "0011011010011010011101101001101001110110100110100111011010011010",
        4  => "1001101101001101001110110100110100111011010011010011101101001101",
        5  => "1100110110100110100111011010011010011101101001101001110110100110",
        6  => "0110011011010011010011101101001101001110110100110100111011010011",
        7  => "1011001101101001101001110110100110100111011010011010011101101001",
        8  => "1101100110110100110100111011010011010011101101001101001110110100",
        9  => "0110110011011010011010011101101001101001110110100110100111011010",
        10 => "1011011001101101001101001110110100110100111011010011010011101101",
        11 => "0101101100110110100110100111011010011010011101101001101001110110",
        12 => "1010110110011011010011010011101101001101001110110100110100111011",
        13 => "1101011011001101101001101001110110100110100111011010011010011101",
        14 => "1110101101100110110100110100111011010011010011101101001101001110",
        15 => "0111010110110011011010011010011101101001101001110110100110100111",
        16 => "1011101011011001101101001101001110110100110100111011010011010011",
        17 => "1101110101101100110110100110100111011010011010011101101001101001",
        18 => "1110111010110110011011010011010011101101001101001110110100110100",
        19 => "0111111010110110011011010011010011101101001101001110110100110100",
        20 => "0011111101011011001101101001101001110110100110100111011010011010",
        21 => "1001111110101101100110110100110100111011010011010011101101001101",
        22 => "1100111111010110110011011010011010011101101001101001110110100110",
        23 => "0110011111101011011001101101001101001110110100110100111011010011",
        24 => "1011001111110101101100110110100110100111011010011010011101101001",
        25 => "1101100111111010110110011011010011010011101101001101001110110100",
        26 => "0110110011111101011011001101101001101001110110100110100111011010",
        27 => "1011011001111110101101100110110100110100111011010011010011101101",
        28 => "1101101100111111010110110011011010011010011101101001101001110110",
        29 => "1110110110011111101011011001101101001101001110110100110100111011",
        30 => "0111011011001111110101101100110110100110100111011010011010011101",
        31 => "1011101101100111111010110110011011010011010011101101001101001110"
    );
    signal processing : std_logic := '0';

begin
    s_ready <= m_ready and not processing;

    process(clk, rst)
        variable row_result : std_logic;
        variable temp_out   : std_logic_vector(OUT_WIDTH - 1 downto 0);
    begin
        if rst = '1' then
            m_data     <= (others => '0');
            m_valid    <= '0';
            processing <= '0';
        elsif rising_edge(clk) then
            m_valid <= '0'; -- domyslny impuls valid

            -- Rozpoczecie gdy pojawia sie poprawne dane wejsciowe i odbiornik jest gotowy
            if s_valid = '1' and (m_ready = '1' and processing = '0') then
                processing <= '1';
                -- y = T * x (operacja bitowa AND, a nastepnie XOR sumujacy wiersz)
                for i in 0 to OUT_WIDTH - 1 loop
                    row_result := '0';
                    for j in 0 to IN_WIDTH - 1 loop
                        row_result := row_result xor (T_MATRIX(i)(j) and s_data(j));
                    end loop;
                    temp_out(i) := row_result;
                end loop;

                m_data     <= temp_out;
                m_valid    <= '1';
                processing <= '0';
            end if;
        end if;
    end process;

end Behavioral;

