library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_throughput_test is
    Port ( 
        clk     : in  STD_LOGIC; -- Zegar 100 MHz (pin L15 na Atlys)
        rst     : in  STD_LOGIC; -- Przycisk resetu
        ctr_out : out STD_LOGIC  -- Wyjscie UART TX do komputera (pin B16)
    );
end top_throughput_test;

architecture Behavioral of top_throughput_test is

    constant TRNG_WIDTH : integer := 64;

    signal trng_data    : std_logic_vector(TRNG_WIDTH - 1 downto 0);
    signal data_ready   : std_logic;
    signal bits_per_sec : std_logic_vector(31 downto 0);

    -- Sygnaly sterujace nadajnikiem UART
    signal uart_busy    : std_logic;
    signal uart_start   : std_logic;
    signal uart_data    : std_logic_vector(7 downto 0);

    -- Maszyna stanów do wysylania 32-bitowego wyniku co 1 sekunde
    type tx_state_type is (IDLE, SEND_B3, SEND_B2, SEND_B1, SEND_B0, SEND_CR, SEND_LF, WAIT_DONE);
    signal tx_state : tx_state_type := IDLE;

    signal stored_throughput : std_logic_vector(31 downto 0);

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

    component trng_throughtput_monitor is
        Port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            data_ready   : in  std_logic;
            bit_width    : in  integer;
            bits_per_sec : out std_logic_vector(31 downto 0)
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

begin

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
            data_ready => data_ready
        );

    -- 2. Instancja monitora przepustowosci (zlicza bity w oknie 1 s)
    monitor_inst : trng_throughtput_monitor
        port map (
            clk          => clk,
            rst          => rst,
            data_ready   => data_ready,
            bit_width    => TRNG_WIDTH,
            bits_per_sec => bits_per_sec
        );

    -- 3. Instancja kontrolera UART (115200 bps)
    uart_inst : usb_ctr
        port map (
            clk       => clk,
            rst       => rst,
            ctr_start => uart_start,
            ctr_data  => uart_data,
            ctr_busy  => uart_busy,
            ctr_out   => ctr_out
        );

    -- 4. Sekwencjoner wysylajacy zmierzona wartosc co 1 sekunde przez UART
    process(clk, rst)
        variable counter_1s : integer range 0 to 100_000_000 := 0;
    begin
        if rst = '1' then
            counter_1s        := 0;
            tx_state          <= IDLE;
            uart_start        <= '0';
            uart_data         <= (others => '0');
            stored_throughput <= (others => '0');
        elsif rising_edge(clk) then
            uart_start <= '0'; -- domyslny impuls trwajacy 1 cykl

            case tx_state is
                when IDLE =>
                    -- Odliczamy dokladnie 1 sekunde (100 000 000 cykli zegara 100 MHz)
                    if counter_1s = 100_000_000 - 1 then
                        counter_1s        := 0;
                        stored_throughput <= bits_per_sec; -- Zamroz aktualny wynik pomiaru
                        tx_state          <= SEND_B3;
                    else
                        counter_1s := counter_1s + 1;
                    end if;

                when SEND_B3 => -- Najstarszy bajt (MSB)
                    if uart_busy = '0' then
                        uart_data  <= stored_throughput(31 downto 24);
                        uart_start <= '1';
                        tx_state   <= SEND_B2;
                    end if;

                when SEND_B2 =>
                    if uart_busy = '0' then
                        uart_data  <= stored_throughput(23 downto 16);
                        uart_start <= '1';
                        tx_state   <= SEND_B1;
                    end if;

                when SEND_B1 =>
                    if uart_busy = '0' then
                        uart_data  <= stored_throughput(15 downto 8);
                        uart_start <= '1';
                        tx_state   <= SEND_B0;
                    end if;

                when SEND_B0 => -- Najmlodszy bajt (LSB)
                    if uart_busy = '0' then
                        uart_data  <= stored_throughput(7 downto 0);
                        uart_start <= '1';
                        tx_state   <= SEND_CR;
                    end if;

                when SEND_CR => 
                    if uart_busy = '0' then
                        uart_data  <= x"0D";
                        uart_start <= '1';
                        tx_state   <= SEND_LF;
                    end if;

                when SEND_LF => -- Znak nowej linii (\n)
                    if uart_busy = '0' then
                        uart_data  <= x"0A";
                        uart_start <= '1';
                        tx_state   <= WAIT_DONE;
                    end if;

                when WAIT_DONE =>
                    if uart_busy = '0' then
                        tx_state <= IDLE;
                    end if;
            end case;
        end if;
    end process;

end Behavioral;