----------------------------------------------------------------------------------
-- Create Date:    28/10/2026 
-- Project Name:   Entropy Extractor
-- Module Name:    top_extractor
-- Target Devices: XC6SLX45 (Spartan 6)
-- Description:    Top-level test module for the Entropy Extractor project. 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_extractor is
    Port ( clk : in  STD_LOGIC;
           rst : in  STD_LOGIC;
           ctr_out : out  STD_LOGIC;
           rst_led : out  STD_LOGIC);
end top_extractor;

architecture Behavioral of top_extractor is

    -- Konfiguracja szerokosci bitowych
    constant TRNG_WIDTH   : integer := 64;
    constant EXT_WIDTH    : integer := 32;
    constant FIFO_WIDTH   : integer := 8;

    -- Sygnaly laczace TRNG z Ekstraktorem
    signal trng_data      : std_logic_vector(TRNG_WIDTH - 1 downto 0);
    signal trng_valid     : std_logic;
    signal trng_ready     : std_logic;

    -- Sygnaly laczace Ekstraktor z FIFO
    signal ext_data       : std_logic_vector(EXT_WIDTH - 1 downto 0);
    signal ext_valid      : std_logic;
    signal ext_ready      : std_logic;

    -- Sygnaly laczace FIFO z Kontrolerem UART
    signal fifo_din       : std_logic_vector(FIFO_WIDTH - 1 downto 0);
    signal fifo_wr_en     : std_logic;
    signal fifo_full      : std_logic;
    
    signal fifo_dout      : std_logic_vector(FIFO_WIDTH - 1 downto 0);
    signal fifo_rd_en     : std_logic;
    signal fifo_empty     : std_logic;

    -- Sygnaly sterujace UART
    signal uart_busy      : std_logic;
    signal uart_start     : std_logic;

    -- Deklaracje komponentów
    component trng_source is
        generic (
            RO_COUNT    : integer := 16;
            RO_LENGTH   : integer := 3;
            OUT_WIDTH   : integer := 64
        );
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            raw_data   : out std_logic_vector(OUT_WIDTH - 1 downto 0);
            data_ready : out std_logic
        );
    end component;

    component toeplitz_extractor is
        generic (
            IN_WIDTH  : integer := 64;
            OUT_WIDTH : integer := 32
        );
        port (
            clk       : in  std_logic;
            rst       : in  std_logic;
            s_data    : in  std_logic_vector(IN_WIDTH - 1 downto 0);
            s_valid   : in  std_logic;
            s_ready   : out std_logic;
            m_data    : out std_logic_vector(OUT_WIDTH - 1 downto 0);
            m_valid   : out std_logic;
            m_ready   : in  std_logic
        );
    end component;

    component fifo_buffer is
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            wr_en    : in  std_logic;
            din      : in  std_logic_vector(7 downto 0);
            full     : out std_logic;
            rd_en    : in  std_logic;
            dout     : out std_logic_vector(7 downto 0);
            empty    : out std_logic
        );
    end component;

    component usb_ctr is
        Port ( 
            clk       : in  STD_LOGIC;
            rst       : in  STD_LOGIC;
            ctr_start : in  STD_LOGIC;
            ctr_data  : in  STD_LOGIC_VECTOR(7 downto 0);
            ctr_busy  : out STD_LOGIC;
            ctr_out   : out STD_LOGIC
        );
    end component;

    -- Pomocniczy rozdzielacz 32-bit -> 8-bit (aby przeslac przez FIFO do UART)
    signal byte_counter : integer range 0 to 3 := 0;

begin
	 rst_led<=rst;	
    -- 1. Instancja generatora surowego szumu TRNG
    trng_inst : trng_source
        generic map (
            RO_COUNT    => 16,
            RO_LENGTH   => 3,
            OUT_WIDTH   => TRNG_WIDTH
        )
        port map (
            clk        => clk,
            rst        => rst,
            raw_data   => trng_data,
            data_ready => trng_valid
        );
    
    -- TRNG w tej architekturze automatycznie wystawia dane, wiec s_ready traktujemy jako stale '1' lub podpinamy sterowanie
    trng_ready <= '1'; 

    -- 2. Instancja ekstraktora Toeplitza z ROM
    extractor_inst : toeplitz_extractor
        generic map (
            IN_WIDTH  => TRNG_WIDTH,
            OUT_WIDTH => EXT_WIDTH
        )
        port map (
            clk       => clk,
            rst       => rst,
            s_data    => trng_data,
            s_valid   => trng_valid,
            s_ready   => open,
            m_data    => ext_data,
            m_valid   => ext_valid,
            m_ready   => ext_ready
        );

    -- Ekstraktor jest gotowy, o ile bufor FIFO nie jest pelny
    ext_ready <= not fifo_full;

    -- 3. Zapis 32-bitowego slowa z ekstraktora do bufora FIFO podzielonego na bajty (8-bit)
    -- Tutaj zapisujemy dane do FIFO, gdy ekstraktor podaje nowe dane (ext_valid = '1')
    fifo_wr_en <= ext_valid and not fifo_full;
    
    -- Przykladowe mapowanie bajtów (wyciaganie kolejnych 8 bitów ze slowa 32-bitowego)
    process(clk, rst)
    begin
        if rst = '1' then
            byte_counter <= 0;
            fifo_din     <= (others => '0');
        elsif rising_edge(clk) then
            if ext_valid = '1' then
                case byte_counter is
                    when 0 => fifo_din <= ext_data(7 downto 0);   byte_counter <= 1;
                    when 1 => fifo_din <= ext_data(15 downto 8);  byte_counter <= 2;
                    when 2 => fifo_din <= ext_data(23 downto 16); byte_counter <= 3;
                    when 3 => fifo_din <= ext_data(31 downto 24); byte_counter <= 0;
                    when others => byte_counter <= 0;
                end case;
            end if;
        end if;
    end process;

    -- Instancja bufora FIFO (BRAM)
    fifo_inst : fifo_buffer
        port map (
            clk   => clk,
            rst   => rst,
            wr_en => fifo_wr_en,
            din   => fifo_din,
            full  => fifo_full,
            rd_en => fifo_rd_en,
            dout  => fifo_dout,
            empty => fifo_empty
        );

    -- 4. Logika odczytu z FIFO i wysylania przez kontroler UART (`usb_ctr`)
    process(clk, rst)
    begin
        if rst = '1' then
            fifo_rd_en <= '0';
            uart_start <= '0';
        elsif rising_edge(clk) then
            fifo_rd_en <= '0';
            uart_start <= '0';

            -- Jesli FIFO nie jest puste, a UART jest wolny - pobierz bajt i wyslij
            if fifo_empty = '0' and uart_busy = '0' and fifo_rd_en = '0' then
                fifo_rd_en <= '1'; -- Sygnal odczytu z FIFO
                uart_start <= '1'; -- Wyzwolenie wyslania przez UART
            end if;
        end if;
    end process;

    -- Instancja kontrolera USB/UART
    uart_inst : usb_ctr
        port map (
            clk       => clk,
            rst       => rst,
            ctr_start => uart_start,
            ctr_data  => fifo_dout,
            ctr_busy  => uart_busy,
            ctr_out   => ctr_out
        );

end Behavioral;

