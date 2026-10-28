----------------------------------------------------------------------------------
-- Create Date:    20/09/2026 
-- Project Name:   Entropy Extractor
-- Module Name:    usb_ctr
-- Target Devices: XC6SLX45 (Spartan 6)
-- Description:    UART Transmitter module acting as a communication controller 
--                 for serial data transmission
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity usb_ctr is
    Port ( 
        clk       : in  STD_LOGIC;
        rst       : in  STD_LOGIC;
        ctr_start : in  STD_LOGIC;	-- Impuls startowy zatrzaskujacy wejscie ctr_data
        ctr_data  : in  STD_LOGIC_VECTOR(7 downto 0); -- Bajt wejsciowy
        ctr_busy  : out STD_LOGIC;	-- Flaga zajetosci kontrolera
        ctr_out   : out STD_LOGIC	-- Linia wyjsciowa Tx
    );
end usb_ctr;

architecture Behavioral of usb_ctr is

    constant CLK_FREQ  : integer := 100_000_000; -- Stale 100 MHz dla Spartan 6
	constant BAUD_RATE : integer := 115_200; -- Parametry polaczenia COM
	constant BIT_LIMIT : integer := CLK_FREQ / BAUD_RATE; -- 868 cykli

    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal current_state : state_type := IDLE;

    signal baud_counter : integer range 0 to BIT_LIMIT := 0;
    signal bit_index    : integer range 0 to 7 := 0;
    signal tx_shift_reg : std_logic_vector(7 downto 0) := (others => '0');

begin
    process(clk, rst)
    begin
        if rising_edge(clk) then
            case current_state is
                -- STAN IDLE: Oczekiwanie na impuls ctr_start
                when IDLE =>
                    ctr_out      <= '1';
                    ctr_busy     <= '0';
                    baud_counter <= 0;
                    bit_index    <= 0;

                    if ctr_start = '1' then
                        tx_shift_reg  <= ctr_data; -- Zatrzasiecie calego bajtu danych
                        ctr_busy      <= '1';
                        current_state <= START_BIT;
                    end if;
                -- STAN START_BIT: Nadawanie bitu startu ('0')
                when START_BIT =>
                    ctr_busy <= '1';
                    ctr_out  <= '0'; -- Bit startu

                    if baud_counter < BIT_LIMIT - 1 then
                        baud_counter <= baud_counter + 1;
                    else
                        baud_counter  <= 0;
                        current_state <= DATA_BITS;
                    end if;
                -- STAN DATA_BITS: Wysylanie 8 bitów danych (najpierw LSB)
                when DATA_BITS =>
                    ctr_busy <= '1';
                    ctr_out  <= tx_shift_reg(bit_index); -- Wysylanie bitu po bicie

                    if baud_counter < BIT_LIMIT - 1 then
                        baud_counter <= baud_counter + 1;
                    else
                        baud_counter <= 0;
                        if bit_index = 7 then
                            bit_index     <= 0;
                            current_state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    end if;
                -- STAN STOP_BIT: Nadawanie bitu stopu ('1')
                when STOP_BIT =>
                    ctr_busy <= '1';
                    ctr_out  <= '1'; -- Bit stopu

                    if baud_counter < BIT_LIMIT - 1 then
                        baud_counter <= baud_counter + 1;
                    else
                        baud_counter  <= 0;
                        ctr_busy      <= '0';
                        current_state <= IDLE;
                    end if;

            end case;
        end if;
    end process;

end Behavioral;