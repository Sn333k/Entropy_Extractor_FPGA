----------------------------------------------------------------------------------
-- Create Date:    20/09/2026 
-- Project Name:   Entropy Extractor
-- Module Name:    top_raw_test
-- Target Devices: XC6SLX45 (Spartan 6)
-- Description:    Temprorarily top-level test module for the Entropy Extractor project. 
--                 This design integrates the True Random Number Generator 
--                 (trng_source) with the UART transmission controller (usb_ctr) 
--                 to continuously stream raw entropy bytes over a serial interface.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_raw_test is
    Port ( 
        clk     : in  STD_LOGIC; -- Zegar
        rst     : in  STD_LOGIC; -- Przycisk resetu
        ctr_out : out STD_LOGIC; -- Wyjscie szeregowe UART TX
		  rst_led : out STD_LOGIC  
    );
end top_raw_test;

architecture Behavioral of top_raw_test is

    -- Sygnaly laczace generator z kontrolerem UART
    signal raw_data   : std_logic_vector(7 downto 0);
    signal data_ready : std_logic;
    signal ctr_busy   : std_logic;
    signal ctr_start  : std_logic;

    -- Instancja generatora szumu (TRNG)
    component trng_source
        generic (
            RO_COUNT    : integer := 16;
            RO_LENGTH   : integer := 3;
            OUT_WIDTH   : integer := 8
        );
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            raw_data   : out std_logic_vector(OUT_WIDTH - 1 downto 0);
            data_ready : out std_logic
        );
    end component;

    -- Instancja kontrolera USB/UART
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

    type state_type is (IDLE, SEND);
    signal current_state : state_type := IDLE;

begin
	rst_led<=rst;
    -- Podlaczenie generatora TRNG
    trng_inst : trng_source
        generic map (
            RO_COUNT  => 16,
            RO_LENGTH => 3,
            OUT_WIDTH => 8
        )
        port map (
            clk        => clk,
            rst        => rst,
            raw_data   => raw_data,
            data_ready => data_ready
        );

    -- Podlaczenie kontrolera UART
    uart_inst : usb_ctr
        port map (
            clk       => clk,
            rst       => rst,
            ctr_start => ctr_start,
            ctr_data  => raw_data,
            ctr_busy  => ctr_busy,
            ctr_out   => ctr_out
        );

    -- Prosta maszyna stanów do obslugi wysylania bajtów
    process(clk, rst)
    begin
        if rst = '1' then
            current_state <= IDLE;
            ctr_start     <= '0';
        elsif rising_edge(clk) then
            ctr_start <= '0'; -- domyslny impuls trwajacy 1 cykl

            case current_state is
                when IDLE =>
                    -- Czekamy az generator dostarczy nowy bajt i UART bedzie wolny
                    if data_ready = '1' and ctr_busy = '0' then
                        ctr_start     <= '1';
                        current_state <= SEND;
                    end if;

                when SEND =>
                    -- Czekamy na zakonczenie nadawania przez UART
                    if ctr_busy = '0' then
                        current_state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;