library ieee;
use ieee.std_logic_1164.all;

entity jogo_reacao is
    port (
        clock        : in  std_logic;
        reset        : in  std_logic;
        jogar        : in  std_logic;
        resposta     : in  std_logic;
        -- displays de 7 segmentos
        display0     : out std_logic_vector(6 downto 0);
        display1     : out std_logic_vector(6 downto 0);
        display2     : out std_logic_vector(6 downto 0);
        display3     : out std_logic_vector(6 downto 0);
        -- indicadores de estado
        ligado       : out std_logic;
        pulso        : out std_logic;
        estimulo     : out std_logic;
        alarme_falso : out std_logic;  -- B1: LED azul (alarme falso)
        erro         : out std_logic;
        pronto       : out std_logic;
        -- debug
        db_estado    : out std_logic_vector(6 downto 0);
		  db_latcha     : out std_logic_vector(2 downto 0);
		  db_latchb     : out std_logic_vector(2 downto 0);
        led_rgb   : out std_logic_vector(2 downto 0)
    );
end entity jogo_reacao;

architecture estrutural of jogo_reacao is

    -- =========================================================================
    -- Declaracoes de componentes
    -- =========================================================================
    component uc_jogo_reacao is
        port (
            clock         : in  std_logic;
            reset         : in  std_logic;
            jogar         : in  std_logic;
            resposta      : in  std_logic;
            tem_falso     : in  std_logic;
            passou_rand   : in  std_logic;
            passou_falso  : in  std_logic;
				passou2s      : in  std_logic;
            passou_metade : in  std_logic;
            ligado        : out std_logic;
            estimulo      : out std_logic;
            alarme_falso  : out std_logic;
            erro          : out std_logic;
            pronto        : out std_logic;
            clr_espera    : out std_logic;
            contar_espera : out std_logic;
            clr_falso     : out std_logic;
            contar_falso  : out std_logic;
            clr_tempo     : out std_logic;
            contar_tempo  : out std_logic;
            sel_erro      : out std_logic;
				gbr           : out std_logic_vector(2 downto 0);
            db_estado     : out std_logic_vector(3 downto 0)
        );
    end component;

    component fd_jogo_reacao is
        port (
            clock         : in  std_logic;
            reset         : in  std_logic;
            clr_espera    : in  std_logic;
            contar_espera : in  std_logic;
            clr_falso     : in  std_logic;
            contar_falso  : in  std_logic;
            clr_tempo     : in  std_logic;
            contar_tempo  : in  std_logic;
            sel_erro      : in  std_logic;
            passou_rand   : out std_logic;
            passou_falso  : out std_logic;
				passou_2s     : out std_logic;
            passou_metade : out std_logic;
            tem_falso     : out std_logic;
            display0      : out std_logic_vector(6 downto 0);
            display1      : out std_logic_vector(6 downto 0);
            display2      : out std_logic_vector(6 downto 0);
            display3      : out std_logic_vector(6 downto 0);
				db_latch_a    : out std_logic_vector(2 downto 0);
				db_latch_b   : out std_logic_vector(2 downto 0);
            db_tempo      : out std_logic_vector(15 downto 0)
        );
    end component;
	 
	 component hex7seg is
        port (
            hex     : in  std_logic_vector(3 downto 0);
            display : out std_logic_vector(6 downto 0)
        );
    end component;

    -- =========================================================================
    -- Sinais de interligacao UC <-> FD
    -- =========================================================================
    -- Fase PREPARA
    signal s_clr_espera    : std_logic;
    signal s_contar_espera : std_logic;
    -- Fase FALSO_ALARME (B1)
    signal s_clr_falso     : std_logic;
    signal s_contar_falso  : std_logic;
    -- Fase MEDE
    signal s_clr_tempo     : std_logic;
    signal s_contar_tempo  : std_logic;
    signal s_sel_erro      : std_logic;
    -- Condicoes de tempo FD -> UC
    signal s_passou_rand   : std_logic;
    signal s_passou_falso  : std_logic;
    signal s_passou_metade : std_logic;
    signal s_tem_falso     : std_logic;
	 signal passou2s_int    : std_logic;
    -- Saidas de estado UC -> portas externas
    signal s_estimulo      : std_logic;
    signal s_alarme_falso  : std_logic;
	 signal db_estado3		: std_logic_vector(3 downto 0);
	 --signal db_latcha       : std_logic_vector(3 downto 0);
	 --signal db_latchb       : std_logic_vector(3 downto 0);

begin

    UC : uc_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
            jogar         => jogar,
            resposta      => resposta,
            tem_falso     => s_tem_falso,
            passou_rand   => s_passou_rand,
            passou_falso  => s_passou_falso,
				passou2s      => passou2s_int,
            passou_metade => s_passou_metade,
            ligado        => ligado,
            estimulo      => s_estimulo,
            alarme_falso  => s_alarme_falso,
            erro          => erro,
            pronto        => pronto,
            clr_espera    => s_clr_espera,
            contar_espera => s_contar_espera,
            clr_falso     => s_clr_falso,
            contar_falso  => s_contar_falso,
            clr_tempo     => s_clr_tempo,
            contar_tempo  => s_contar_tempo,
            sel_erro      => s_sel_erro,
				gbr 			  => led_rgb,
            db_estado     => db_estado3
        );

    FD : fd_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
            clr_espera    => s_clr_espera,
            contar_espera => s_contar_espera,
            clr_falso     => s_clr_falso,
            contar_falso  => s_contar_falso,
            clr_tempo     => s_clr_tempo,
            contar_tempo  => s_contar_tempo,
            sel_erro      => s_sel_erro,
            passou_rand   => s_passou_rand,
            passou_falso  => s_passou_falso,
				passou_2s     => passou2s_int,
            passou_metade => s_passou_metade,
            tem_falso     => s_tem_falso,
            display0      => display0,
            display1      => display1,
            display2      => display2,
            display3      => display3,
				db_latch_a    => db_latcha,
				db_latch_b    => db_latchb,
            db_tempo      => open
        );

    estimulo     <= s_estimulo;
	 
    alarme_falso <= s_alarme_falso;
    
	 pulso        <= s_estimulo and (not resposta);  
	 
	 hx : hex7seg
		port map(db_estado3, db_estado);

end architecture;
