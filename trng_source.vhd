library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity trng_source is
    generic (
        RO_COUNT    : integer := 16; -- Liczba równoleglych pierscieni oscylacyjnych
        RO_LENGTH   : integer := 3;  -- Liczba inverterów w jednym pierscieniu (nieparzysta!)
        OUT_WIDTH   : integer := 8   -- Szerokosc szyny wyjsciowej (np. 8, 16, 32 bity)
    );
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        raw_data   : out std_logic_vector(OUT_WIDTH - 1 downto 0);
        data_ready : out std_logic   -- Flaga wygenerowania nowej próbki surowej
    );
end trng_source;

architecture Behavioral of trng_source is

    -- Typy pomocnicze dla struktur pierscieni
    type ro_chain_type is array (0 to RO_LENGTH - 1) of std_logic;
    type ro_array_type is array (0 to RO_COUNT - 1) of ro_chain_type;

    signal ro_nodes : ro_array_type;
    signal ro_outputs : std_logic_vector(RO_COUNT - 1 downto 0);

    -- Rejestry próbkowania i synchronizacji (2-flopy synchronizer eliminuje metastabilnosc)
    signal sampled_ro  : std_logic_vector(RO_COUNT - 1 downto 0) := (others => '0');
    signal sync_ro     : std_logic_vector(RO_COUNT - 1 downto 0) := (others => '0');

    -- Rejestr gromadzenia bitów wyjsciowych
    signal shift_reg   : std_logic_vector(OUT_WIDTH - 1 downto 0) := (others => '0');
    signal bit_counter : integer range 0 to OUT_WIDTH := 0;

    -- ATRYBUTY XILINX ISE - Zapobiegaja usuwaniu / optymalizowaniu petli kombinacyjnych przez XST
    attribute KEEP : string;
    attribute DONT_TOUCH : string;
    attribute ALLOW_COMBINATORIAL_LOOPS : string;

    attribute KEEP of ro_nodes : signal is "TRUE";
    attribute DONT_TOUCH of ro_nodes : signal is "TRUE";
    attribute ALLOW_COMBINATORIAL_LOOPS of ro_nodes : signal is "TRUE";

begin

    -- 1. Generowanie struktury Ring Oscillators
    gen_ro : for i in 0 to RO_COUNT - 1 generate
        -- Pierwszy negator w petli z sygnalem resetu (opóznienie 'after 1 ns' zapobiega 'zero delay oscillation')
        ro_nodes(i)(0) <= not (ro_nodes(i)(RO_LENGTH - 1) and not rst) after 1 ns;
        -- Kolejne negatory w petli
        gen_chain : for j in 1 to RO_LENGTH - 1 generate
            ro_nodes(i)(j) <= not ro_nodes(i)(j - 1) after 1 ns;
        end generate gen_chain;
        -- Wyjscie pojedynczego pierscienia
        ro_outputs(i) <= ro_nodes(i)(0);
    end generate gen_ro;

    -- 2. Próbkowanie, synchronizacja i zbieranie próbek w zegarze systemowym
    process(clk, rst)
        variable xor_sum : std_logic;
    begin
        if rst = '1' then
            sampled_ro  <= (others => '0');
            sync_ro     <= (others => '0');
            shift_reg   <= (others => '0');
            bit_counter <= 0;
            raw_data    <= (others => '0');
            data_ready  <= '0';

        elsif rising_edge(clk) then
            -- Dwu-stopniowa synchronizacja zapobiegajaca metastabilnosci
            sampled_ro <= ro_outputs;
            sync_ro    <= sampled_ro;
            -- Mieszanie wyjsc ze wszystkich pierscieni oscylacyjnych za pomoca drzewa XOR
            xor_sum := '0';
            for k in 0 to RO_COUNT - 1 loop
                xor_sum := xor_sum xor sync_ro(k);
            end loop;
            -- Gromadzenie surowych bitów do pelnej szyny wyjsciowej (OUT_WIDTH bitów)
            if bit_counter < OUT_WIDTH then
                shift_reg   <= shift_reg(OUT_WIDTH - 2 downto 0) & xor_sum;
                bit_counter <= bit_counter + 1;
                data_ready  <= '0';
            else
                raw_data    <= shift_reg;
                data_ready  <= '1';
                bit_counter <= 0; -- Reset licznika i start kolejnego bajtu/slowa
            end if;

        end if;
    end process;

end Behavioral;