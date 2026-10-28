library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_trng_source is
-- Testbench nie posiada portów zewnetrznych
end tb_trng_source;

architecture Behavioral of tb_trng_source is

    -- Stale do konfiguracji testowanego modulu
    constant RO_COUNT_TB  : integer := 16;
    constant RO_LENGTH_TB : integer := 3;
    constant OUT_WIDTH_TB : integer := 8; -- Generator bedzie skladal 8-bitowe bajty

    -- Deklaracja testowanego komponentu (UUT)
    component trng_source
        generic (
            RO_COUNT  : integer := 16;
            RO_LENGTH : integer := 3;
            OUT_WIDTH : integer := 8
        );
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            raw_data   : out std_logic_vector(OUT_WIDTH - 1 downto 0);
            data_ready : out std_logic
        );
    end component;

    -- Sygnaly testowe
    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal raw_data   : std_logic_vector(OUT_WIDTH_TB - 1 downto 0);
    signal data_ready : std_logic;

    -- Okres zegara systemowego (50 MHz = 20 ns)
    constant CLK_PERIOD : time := 20 ns;

begin

    -- Instancja testowanego modulu (UUT)
    uut: trng_source
        generic map (
            RO_COUNT  => RO_COUNT_TB,
            RO_LENGTH => RO_LENGTH_TB,
            OUT_WIDTH => OUT_WIDTH_TB
        )
        port map (
            clk        => clk,
            rst        => rst,
            raw_data   => raw_data,
            data_ready => data_ready
        );

    -- Generator zegara systemowego 50 MHz
    clk_process : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;

    -- Glówny proces stymulacji
    stim_proc: process
    begin
        --Inicjalizacja i Reset ukladu
        rst <= '1';
        wait for 100 ns;
        -- Zwolnienie resetu - uruchomienie oscylacji i petli
        rst <= '0';
        wait for CLK_PERIOD * 2;
        -- Obserwacja generowania pierwszego bajtu
        -- Uklad potrzebuje OUT_WIDTH cykli na zebranie pelnego bajtu
        wait until data_ready = '1';
        report "Wygenerowano pierwszy bajt surowy: " & integer'image(to_integer(unsigned(raw_data))) severity note;
        
		  -- Obserwacja kolejnych 5 bajtów danych
        for i in 1 to 5 loop
            wait until data_ready = '1';
            report "Wygenerowano bajt nr " & integer'image(i + 1) & ": " & integer'image(to_integer(unsigned(raw_data))) severity note;
        
		  end loop;
        wait;
    end process;

end Behavioral;