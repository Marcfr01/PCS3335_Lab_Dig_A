-- =============================================================================
-- ps2_decoder.vhd
-- Camada de protocolo PS/2 — Scancode Set 2.
-- Responsabilidade: distinguir make codes (tecla pressionada) de
-- break codes (tecla solta, prefixados por 0xF0), e sinalizar eventos.
--
-- Referência: "PS/2 Mouse/Keyboard Protocol", Adam Chapweske (2003);
--             Scancode Set 2 é o padrão de teclados IBM PC/AT modernos.
--
-- Lógica:
--   - Byte 0xF0 recebido → próximo byte é break code (tecla solta)
--   - Byte 0xE0 recebido → próximo byte é scancode estendido
--   - Demais bytes       → make code (tecla pressionada)
--
-- Entradas:
--   clk        : clock do sistema
--   rst        : reset síncrono, ativo alto
--   scancode   : byte vindo do ps2_receiver
--   parity_ok  : '1' se frame físico é válido
--   data_ready : pulso indicando novo byte disponível
--
-- Saídas:
--   key_code   : scancode final da tecla (sem prefixo 0xF0/0xE0)
--   key_make   : '1' → tecla pressionada (make event)
--   key_break  : '1' → tecla solta      (break event)
--   key_valid  : pulso de 1 ciclo junto com make ou break
--   extended   : '1' se código estendido (prefixado por 0xE0)
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity ps2_decoder is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;

        scancode   : in  std_logic_vector(7 downto 0);
        parity_ok  : in  std_logic;
        data_ready : in  std_logic;

        key_code   : out std_logic_vector(7 downto 0);
        key_make   : out std_logic;
        key_break  : out std_logic;
        key_valid  : out std_logic;
        extended   : out std_logic
    );
end entity ps2_decoder;

architecture rtl of ps2_decoder is

    -- Constantes de protocolo PS/2 Scancode Set 2
    constant BREAK_PREFIX    : std_logic_vector(7 downto 0) := x"F0";
    constant EXTENDED_PREFIX : std_logic_vector(7 downto 0) := x"E0";

    -- Máquina de estados do decodificador
    type state_t is (ST_IDLE, ST_EXTENDED, ST_BREAK, ST_EXT_BREAK);
    signal state      : state_t := ST_IDLE;
    signal next_state : state_t;

    -- Sinais de saída internos
    signal key_code_i  : std_logic_vector(7 downto 0) := (others => '0');
    signal key_make_i  : std_logic := '0';
    signal key_break_i : std_logic := '0';
    signal key_valid_i : std_logic := '0';
    signal extended_i  : std_logic := '0';

begin

    -- =========================================================================
    -- Registro de estado
    -- =========================================================================
    state_reg : process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                state <= ST_IDLE;
            else
                state <= next_state;
            end if;
        end if;
    end process state_reg;

    -- =========================================================================
    -- Lógica combinacional: próximo estado + geração de eventos
    --
    -- Diagrama de transições:
    --
    --   ST_IDLE ──[E0]──► ST_EXTENDED ──[F0]──► ST_EXT_BREAK ──[key]──► ST_IDLE
    --      │                   │                                              ▲
    --      │[F0]               │[key] → make_ext                             │
    --      ▼                   └─────────────────────────────────────────────┘
    --   ST_BREAK ──[key]──► ST_IDLE (break event)
    --      ▲
    --   [qualquer key normal → make event, volta a ST_IDLE]
    -- =========================================================================
    decode_proc : process(clk)
    begin
        if rising_edge(clk) then
            -- Defaults (sinais de pulso)
            key_valid_i <= '0';
            key_make_i  <= '0';
            key_break_i <= '0';

            if rst = '1' then
                next_state  <= ST_IDLE;
                key_code_i  <= (others => '0');
                extended_i  <= '0';
            elsif data_ready = '1' and parity_ok = '1' then
                case state is

                    -- ---------------------------------------------------------
                    when ST_IDLE =>
                        if scancode = EXTENDED_PREFIX then
                            next_state <= ST_EXTENDED;

                        elsif scancode = BREAK_PREFIX then
                            next_state <= ST_BREAK;

                        else
                            -- Make code normal
                            key_code_i  <= scancode;
                            extended_i  <= '0';
                            key_make_i  <= '1';
                            key_valid_i <= '1';
                            next_state  <= ST_IDLE;
                        end if;

                    -- ---------------------------------------------------------
                    when ST_EXTENDED =>
                        if scancode = BREAK_PREFIX then
                            -- Sequência E0 F0 → break estendido
                            next_state <= ST_EXT_BREAK;
                        else
                            -- Make estendido
                            key_code_i  <= scancode;
                            extended_i  <= '1';
                            key_make_i  <= '1';
                            key_valid_i <= '1';
                            next_state  <= ST_IDLE;
                        end if;

                    -- ---------------------------------------------------------
                    when ST_BREAK =>
                        -- Byte após F0: break code normal
                        key_code_i  <= scancode;
                        extended_i  <= '0';
                        key_break_i <= '1';
                        key_valid_i <= '1';
                        next_state  <= ST_IDLE;

                    -- ---------------------------------------------------------
                    when ST_EXT_BREAK =>
                        -- Byte após E0 F0: break code estendido
                        key_code_i  <= scancode;
                        extended_i  <= '1';
                        key_break_i <= '1';
                        key_valid_i <= '1';
                        next_state  <= ST_IDLE;

                    -- ---------------------------------------------------------
                    when others =>
                        next_state <= ST_IDLE;

                end case;
            else
                next_state <= state; -- mantém estado se não há dado novo
            end if;
        end if;
    end process decode_proc;

    -- Saídas
    key_code  <= key_code_i;
    key_make  <= key_make_i;
    key_break <= key_break_i;
    key_valid <= key_valid_i;
    extended  <= extended_i;

end architecture rtl;