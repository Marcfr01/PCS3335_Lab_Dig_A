library ieee;
use ieee.std_logic_1164.all;

entity ps2_top is
    port (
        clk      : in  std_logic;   -- clock do sistema (50 MHz típico)
        rst      : in  std_logic;   -- reset síncrono, ativo alto

        -- Interface física PS/2
        ps2_clk  : in  std_logic;
        ps2_data : in  std_logic;

        -- Interface de alto nível para o sistema
        key_code  : out std_logic_vector(7 downto 0); -- scancode da tecla
        key_make  : out std_logic;                    -- '1': tecla pressionada
        key_break : out std_logic;                    -- '1': tecla solta
        key_valid : out std_logic;                    -- pulso: evento válido
        extended  : out std_logic                     -- '1': código estendido (E0)
    );
end entity ps2_top;

architecture structural of ps2_top is

    -- -------------------------------------------------------------------------
    -- Declarações de componentes
    -- -------------------------------------------------------------------------
    component ps2_receiver is
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            ps2_clk    : in  std_logic;
            ps2_data   : in  std_logic;
            scancode   : out std_logic_vector(7 downto 0);
            parity_ok  : out std_logic;
            data_ready : out std_logic
        );
    end component;

    component ps2_decoder is
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
    end component;

    -- -------------------------------------------------------------------------
    -- Sinais internos de interconexão
    -- -------------------------------------------------------------------------
    signal scancode_w   : std_logic_vector(7 downto 0);
    signal parity_ok_w  : std_logic;
    signal data_ready_w : std_logic;

begin

    -- -------------------------------------------------------------------------
    -- Instância 1: camada física — recepção serial PS/2
    -- -------------------------------------------------------------------------
    u_receiver : ps2_receiver
        port map (
            clk        => clk,
            rst        => rst,
            ps2_clk    => ps2_clk,
            ps2_data   => ps2_data,
            scancode   => scancode_w,
            parity_ok  => parity_ok_w,
            data_ready => data_ready_w
        );

    -- -------------------------------------------------------------------------
    -- Instância 2: camada de protocolo — decodificação make/break
    -- -------------------------------------------------------------------------
    u_decoder : ps2_decoder
        port map (
            clk        => clk,
            rst        => rst,
            scancode   => scancode_w,
            parity_ok  => parity_ok_w,
            data_ready => data_ready_w,
            key_code   => key_code,
            key_make   => key_make,
            key_break  => key_break,
            key_valid  => key_valid,
            extended   => extended
        );

end architecture structural;