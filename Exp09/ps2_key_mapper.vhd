-- =============================================================================
-- ps2_key_mapper.vhd
-- Mapeia scancodes PS/2 (Scancode Set 2) das teclas S D F G H J K
-- para o vetor resposta(6 downto 0).
--
-- Mapeamento:
--   resposta(0) → tecla S  (scancode 0x1B)
--   resposta(1) → tecla D  (scancode 0x23)
--   resposta(2) → tecla F  (scancode 0x2B)
--   resposta(3) → tecla G  (scancode 0x34)
--   resposta(4) → tecla H  (scancode 0x33)
--   resposta(5) → tecla J  (scancode 0x3B)
--   resposta(6) → tecla K  (scancode 0x42)
--
-- Comportamento:
--   - make event (key_make='1'): bit correspondente vai para '1'
--   - break event (key_break='1'): bit correspondente volta para '0'
--   - Teclas não mapeadas são ignoradas
--   - reset síncrono zera todos os bits
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity ps2_key_mapper is
    port (
        clk       : in  std_logic;
        rst       : in  std_logic;

        -- Vindos do ps2_decoder
        key_code  : in  std_logic_vector(7 downto 0);
        key_make  : in  std_logic;
        key_break : in  std_logic;
        key_valid : in  std_logic;

        -- Saída: bit i = '1' enquanto a tecla i estiver pressionada
        resposta  : out std_logic_vector(6 downto 0)
    );
end entity ps2_key_mapper;

architecture rtl of ps2_key_mapper is

    -- Scancodes Set 2 das teclas mapeadas
    constant SC_S : std_logic_vector(7 downto 0) := x"1B";
    constant SC_D : std_logic_vector(7 downto 0) := x"23";
    constant SC_F : std_logic_vector(7 downto 0) := x"2B";
    constant SC_G : std_logic_vector(7 downto 0) := x"34";
    constant SC_H : std_logic_vector(7 downto 0) := x"33";
    constant SC_J : std_logic_vector(7 downto 0) := x"3B";
    constant SC_K : std_logic_vector(7 downto 0) := x"42";

    signal estado_teclas : std_logic_vector(6 downto 0) := (others => '0');

begin

    process(clk)
    begin
        if rising_edge(clk) then
            if rst = '1' then
                estado_teclas <= (others => '0');

            elsif key_valid = '1' then
                if key_make = '1' then
                    -- Tecla pressionada: seta bit correspondente
                    case key_code is
                        when SC_S => estado_teclas(0) <= '1';
                        when SC_D => estado_teclas(1) <= '1';
                        when SC_F => estado_teclas(2) <= '1';
                        when SC_G => estado_teclas(3) <= '1';
                        when SC_H => estado_teclas(4) <= '1';
                        when SC_J => estado_teclas(5) <= '1';
                        when SC_K => estado_teclas(6) <= '1';
                        when others => null;
                    end case;

                elsif key_break = '1' then
                    -- Tecla solta: limpa bit correspondente
                    case key_code is
                        when SC_S => estado_teclas(0) <= '0';
                        when SC_D => estado_teclas(1) <= '0';
                        when SC_F => estado_teclas(2) <= '0';
                        when SC_G => estado_teclas(3) <= '0';
                        when SC_H => estado_teclas(4) <= '0';
                        when SC_J => estado_teclas(5) <= '0';
                        when SC_K => estado_teclas(6) <= '0';
                        when others => null;
                    end case;
                end if;
            end if;
        end if;
    end process;

    resposta <= estado_teclas;

end architecture rtl;