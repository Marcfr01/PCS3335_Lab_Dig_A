library ieee;
use ieee.std_logic_1164.all;

entity jogo_reacao is
    port (
        clock    : in  std_logic;
        reset    : in  std_logic;
        jogar    : in  std_logic;
        resposta : in  std_logic;
        display0 : out std_logic_vector(6 downto 0);
        display1 : out std_logic_vector(6 downto 0);
        display2 : out std_logic_vector(6 downto 0);
        display3 : out std_logic_vector(6 downto 0);
        ligado   : out std_logic;
        pulso    : out std_logic;
        estimulo : out std_logic;
        erro     : out std_logic;
        pronto   : out std_logic;
        db_estado : out std_logic_vector(3 downto 0);
        db_tempo  : out std_logic_vector(15 downto 0)
    );
end entity jogo_reacao;

architecture estrutural of jogo_reacao is

    component uc_jogo_reacao is
        port (
            clock         : in  std_logic;
            reset         : in  std_logic;
            jogar         : in  std_logic;
            resposta      : in  std_logic;
            passou5s      : in  std_logic;
            ligado        : out std_logic;
            estimulo      : out std_logic;
            erro          : out std_logic;
            pronto        : out std_logic;
            clr_espera    : out std_logic;
            contar_espera : out std_logic;
            clr_tempo     : out std_logic;
            contar_tempo  : out std_logic;
            sel_erro      : out std_logic;
            db_estado     : out std_logic_vector(3 downto 0)
        );
    end component;

    component fd_jogo_reacao is
        port (
            clock         : in  std_logic;
            reset         : in  std_logic;
            clr_espera    : in  std_logic;
            contar_espera : in  std_logic;
            clr_tempo     : in  std_logic;
            contar_tempo  : in  std_logic;
            sel_erro      : in  std_logic;
            passou5s      : out std_logic;
            display0      : out std_logic_vector(6 downto 0);
            display1      : out std_logic_vector(6 downto 0);
            display2      : out std_logic_vector(6 downto 0);
            display3      : out std_logic_vector(6 downto 0);
            db_tempo      : out std_logic_vector(15 downto 0)
        );
    end component;

    signal s_clr_espera    : std_logic;
    signal s_contar_espera : std_logic;
    signal s_clr_tempo     : std_logic;
    signal s_contar_tempo  : std_logic;
    signal s_sel_erro      : std_logic;

    signal s_passou5s      : std_logic;

    signal s_estimulo      : std_logic;

begin

    UC : uc_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
            jogar         => jogar,
            resposta      => resposta,
            passou5s      => s_passou5s,
            ligado        => ligado,
            estimulo      => s_estimulo,
            erro          => erro,
            pronto        => pronto,
            clr_espera    => s_clr_espera,
            contar_espera => s_contar_espera,
            clr_tempo     => s_clr_tempo,
            contar_tempo  => s_contar_tempo,
            sel_erro      => s_sel_erro,
            db_estado     => db_estado
        );

    FD : fd_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
            clr_espera    => s_clr_espera,
            contar_espera => s_contar_espera,
            clr_tempo     => s_clr_tempo,
            contar_tempo  => s_contar_tempo,
            sel_erro      => s_sel_erro,
            passou5s      => s_passou5s,
            display0      => display0,
            display1      => display1,
            display2      => display2,
            display3      => display3,
            db_tempo      => db_tempo
        );

    estimulo <= s_estimulo;

    pulso <= s_estimulo and (not resposta);

end architecture;
