library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fifo_buffer is
    generic (
        DATA_WIDTH : integer := 8;
        FIFO_DEPTH : integer := 1024
    );
    port (
        clk   : in  std_logic;
        rst   : in  std_logic;

        wr_en : in  std_logic;                         -- Sygnal zezwolenia na zapis
        din   : in  std_logic_vector(DATA_WIDTH - 1 downto 0); -- Dane wejsciowe
        full  : out std_logic;                         -- Flaga pelnego bufora

        rd_en : in  std_logic;                         -- Sygnal zezwolenia na odczyt
        dout  : out std_logic_vector(DATA_WIDTH - 1 downto 0); -- Dane wyjsciowe
        empty : out std_logic                          -- Flaga pustego bufora
    );
end fifo_buffer;

architecture Behavioral of fifo_buffer is

    -- Typ pamieci dwuportowej reprezentujacy Block RAM
    type memory_type is array (0 to FIFO_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal ram : memory_type := (others => (others => '0'));

    -- Wskazniki adresu zapisu i odczytu
    signal wr_ptr : integer range 0 to FIFO_DEPTH - 1 := 0;
    signal rd_ptr : integer range 0 to FIFO_DEPTH - 1 := 0;

    -- Licznik elementów w buforze
    signal count  : integer range 0 to FIFO_DEPTH := 0;

    -- Sygnaly pomocnicze flag
    signal full_i  : std_logic := '0';
    signal empty_i : std_logic := '1';

    --Wymuszanie syntezy do BlockRAM
    attribute ram_style : string;
    attribute ram_style of ram : signal is "block";

begin

    full_i  <= '1' when count = FIFO_DEPTH else '0';
    empty_i <= '1' when count = 0 else '0';

    full  <= full_i;
    empty <= empty_i;

    process(clk, rst)
    begin
        if rst = '1' then
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            dout   <= (others => '0');

        elsif rising_edge(clk) then

            -- Zapis i odczyt jednoczesnie
            if (wr_en = '1' and full_i = '0') and (rd_en = '1' and empty_i = '0') then
                ram(wr_ptr) <= din;
                dout        <= ram(rd_ptr);
                
                if wr_ptr = FIFO_DEPTH - 1 then
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
                end if;

                if rd_ptr = FIFO_DEPTH - 1 then
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;
                end if;

                count <= count;

            -- Tylko Zapis
            elsif (wr_en = '1' and full_i = '0') then
                ram(wr_ptr) <= din;
                
                if wr_ptr = FIFO_DEPTH - 1 then
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;
                end if;

                count <= count + 1;

            -- Tylko Odczyt
            elsif (rd_en = '1' and empty_i = '0') then
                dout <= ram(rd_ptr);

                if rd_ptr = FIFO_DEPTH - 1 then
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;
                end if;

                count <= count - 1;
            end if;

        end if;
    end process;

end Behavioral;

