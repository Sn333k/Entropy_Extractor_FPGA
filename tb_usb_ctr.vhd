library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_usb_ctr is
-- Testbench nie posiada portów zewnetrznych
end tb_usb_ctr;

architecture Behavioral of tb_usb_ctr is

    component usb_ctr
        Port ( 
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            ctr_start : in  STD_LOGIC;
            ctr_data  : in  STD_LOGIC_VECTOR(7 downto 0);
            ctr_busy  : out STD_LOGIC;
            ctr_out   : out STD_LOGIC
        );
    end component;

    signal clk       : std_logic := '0';
    signal rst       : std_logic := '1';
    signal ctr_start : std_logic := '0';
    signal ctr_data  : std_logic_vector(7 downto 0) := (others => '0');
    signal ctr_busy  : std_logic;
    signal ctr_out   : std_logic;

    constant CLK_PERIOD : time := 20 ns;

begin
    uut: usb_ctr
        port map (
            clk       => clk,
            rst       => rst,
            ctr_start => ctr_start,
            ctr_data  => ctr_data,
            ctr_busy  => ctr_busy,
            ctr_out   => ctr_out
        );

    
    clk_process : process -- Generator zegara (50 MHz)
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;


    stim_proc: process
    begin
        ------------------------------------------------------------
        -- 1. Inicjalizacja i Reset ukladu
        rst <= '1';
        wait for 100 ns;
        
        rst <= '0';
        wait for CLK_PERIOD * 5;

        ------------------------------------------------------------
        -- 2. Test 1: Wysylanie pierwszego bajtu (0xA5 = "10100101")
        ctr_data  <= "10100101"; -- 0xA5
        ctr_start <= '1';
        wait for CLK_PERIOD;     -- Impuls startu trwa 1 cykl zegara
        ctr_start <= '0';
		  
        wait until ctr_busy = '0'; -- Czekamy na powrót sygnalu busy do stanu niskiego ('0')
        wait for 2 us;

        ------------------------------------------------------------
        -- 3. Test 2: Wysylanie drugiego bajtu (0x3F = "00111111")
        ctr_data  <= "00111111"; -- 0x3F
        ctr_start <= '1';
        wait for CLK_PERIOD;
        ctr_start <= '0';
		  
        wait until ctr_busy = '0';
        wait for 5 us;

        report "Symulacja zakonczona pomyslnie" severity note;
        wait;
    end process;

end Behavioral;