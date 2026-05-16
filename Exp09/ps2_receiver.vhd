-- =============================================================================
-- ps2_receiver.vhd
-- Camada física do protocolo PS/2.
-- Responsabilidade: capturar os 11 bits do frame serial (start, 8 data,
-- parity, stop) sincronizados na borda de DESCIDA do PS2_CLK.
--
-- Protocolo PS/2 (referência: "Digital Design and Computer Architecture",
-- Harris & Harris, Cap. 8 — Serial Interfaces):
--   Frame: [START=0][D0..D7][PARITY_ODD][STOP=1]
--   Clock: ~10–16.7 kHz; dados válidos na borda de descida.
--
-- Entradas:
--   clk       : clock do sistema (ex: 50 MHz)
--   rst       : reset síncrono, ativo alto
--   ps2_clk   : clock serial vindo do teclado
--   ps2_data  : dado serial vindo do teclado
--
-- Saídas:
--   scancode  : byte recebido (bits D0..D7 do frame)
--   parity_ok : '1' se paridade ímpar confere
--   data_ready: pulso de 1 ciclo indicando frame completo e válido
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ps2_receiver is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        ps2_clk    : in  std_logic;
        ps2_data   : in  std_logic;

        scancode   : out std_logic_vector(7 downto 0);
        parity_ok  : out std_logic;
        data_ready : out std_logic
    );
end entity ps2_receiver;

architecture rtl of ps2_receiver is

    -- -------------------------------------------------------------------------
    -- Sincronização do PS2_CLK para o domínio do clock do sistema
    -- (2 flip-flops em cascata eliminam metaestabilidade)
    -- -------------------------------------------------------------------------
    signal ps2_clk_sync  : std_logic_vector(2 downto 0) := (others => '1');
    signal ps2_data_sync : std_logic_vector(1 downto 0) := (others => '1');
    signal falling_edge_ps2 : std_logic;

    -- -------------------------------------------------------------------------
    -- Registrador de deslocamento: 11 bits (start + 8 data + parity + stop)
    -- -------------------------------------------------------------------------
    signal shift_reg  : std_logic_vector(10 downto 0) := (others => '0');
    signal bit_count  : unsigned(3 downto 0) := (others => '0'); -- 0 a 11

    -- Sinais internos de saída
    signal scancode_i  : std_logic_vector(7 downto 0) := (others => '0');
    signal parity_ok_i : std_logic := '0';
    signal ready_i     : std_logic := '0';

begin

    -- =========================================================================
    -- 1. SINCRONIZAÇÃO DOS SINAIS PS/2 → domínio do clock do sistema
    -- =========================================================================
    sync_proc : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                ps2_clk_sync  <= (others => '1');
                ps2_data_sync <= (others => '1');
            else
                ps2_clk_sync  <= ps2_clk_sync(1 downto 0) & ps2_clk;
                ps2_data_sync <= ps2_data_sync(0) & ps2_data;
            end if;
        end if;
    end process sync_proc;

    -- Detecta borda de descida: andér anterior '1', atual '0'
    falling_edge_ps2 <= ps2_clk_sync(2) and (not ps2_clk_sync(1));

    -- =========================================================================
    -- 2. RECEPÇÃO SERIAL — registrador de deslocamento de 11 bits
    --    Amostra ps2_data na borda de descida detectada
    -- =========================================================================
    receive_proc : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                shift_reg  <= (others => '0');
                bit_count  <= (others => '0');
                ready_i    <= '0';
            else
                ready_i <= '0'; -- pulso de 1 ciclo

                if falling_edge_ps2 = '1' then
                    -- Desloca entrada no MSB; após 11 bits o frame está completo
                    shift_reg <= ps2_data_sync(1) & shift_reg(10 downto 1);
                    bit_count <= bit_count + 1;

                    if bit_count = 10 then
                        -- Frame completo: 11 bits recebidos (índice 0 a 10)
                        bit_count <= (others => '0');
                        ready_i   <= '1';
                    end if;
                end if;
            end if;
        end if;
    end process receive_proc;

    -- =========================================================================
    -- 3. EXTRAÇÃO E VERIFICAÇÃO
    --    Frame final em shift_reg após 11 bits:
    --      shift_reg(0)          = START (deve ser '0')
    --      shift_reg(8 downto 1) = D0..D7
    --      shift_reg(9)          = PARITY (paridade ímpar)
    --      shift_reg(10)         = STOP  (deve ser '1')
    -- =========================================================================
    extract_proc : process(clk)
        variable parity_xor : std_logic;
    begin
        if rising_edge(clk) then
            if rst = '1' then
                scancode_i  <= (others => '0');
                parity_ok_i <= '0';
            elsif ready_i = '1' then
                scancode_i <= shift_reg(8 downto 1);

                -- Paridade ímpar: XOR de todos os 8 bits de dado + bit de
                -- paridade deve ser '1'
                parity_xor := shift_reg(1) xor shift_reg(2) xor
                               shift_reg(3) xor shift_reg(4) xor
                               shift_reg(5) xor shift_reg(6) xor
                               shift_reg(7) xor shift_reg(8) xor
                               shift_reg(9);

                if parity_xor = '1'           and  -- paridade ímpar confere
                   shift_reg(0)  = '0'        and  -- START = 0
                   shift_reg(10) = '1'        then  -- STOP  = 1
                    parity_ok_i <= '1';
                else
                    parity_ok_i <= '0';
                end if;
            end if;
        end if;
    end process extract_proc;

    -- Saídas
    scancode   <= scancode_i;
    parity_ok  <= parity_ok_i;
    data_ready <= ready_i;

end architecture rtl;