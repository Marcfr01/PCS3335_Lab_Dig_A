library ieee;
use ieee.std_logic_1164.all;

entity jogo_reacao is
    port (
        clock    		: in  std_logic;
        reset    		: in  std_logic;
        jogar    		: in  std_logic;
		  botao_next   : in  std_logic;
		  botao_sel    : in  std_logic;
        resposta 		: in  std_logic;
        display0 		: out std_logic_vector(6 downto 0);
        display1 		: out std_logic_vector(6 downto 0);
        display2 		: out std_logic_vector(6 downto 0);
        display3 		: out std_logic_vector(6 downto 0);
        ligado   		: out std_logic;
        pulso    		: out std_logic;
        estimulo 		: out std_logic;
        erro     		: out std_logic;
        pronto   		: out std_logic;
		  gbr          : out std_logic_vector(2 downto 0);
        db_estado 	: out std_logic_vector(3 downto 0);
        db_tempo  	: out std_logic_vector(15 downto 0)
    );
end entity jogo_reacao;

architecture estrutural of jogo_reacao is

    component uc_jogo_reacao is
        port (
			  clock         : in  std_logic;
			  reset         : in  std_logic;
			  jogar         : in  std_logic;
			  botao_next    : in  std_logic;
			  botao_sel     : in  std_logic;
			  resposta      : in  std_logic;
			  passou5s      : in  std_logic;   
			  ligado        : out std_logic;
			  perdeu        : out std_logic;
			  tocar1        : out std_logic;
			  tocar2        : out std_logic;
			  db_estado     : out std_logic_vector(3 downto 0)
        );
    end component;

    component fd_jogo_reacao is
        port (
			  clock         : in  std_logic;
			  reset         : in  std_logic;
			  tocar1        : in  std_logic;
			  tocar2        : in  std_logic;
			  display0      : out std_logic_vector(6 downto 0);
			  display1      : out std_logic_vector(6 downto 0);
			  display2      : out std_logic_vector(6 downto 0);
			  display3      : out std_logic_vector(6 downto 0);
			  rgb           : out std_logic_vector(2 downto 0);
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
	 
	 signal s_perdeu        : std_logic;
	 signal s_tocar1, s_tocar2  : std_logic;

begin

    UC : uc_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
            jogar         => jogar,
				botao_next    => botao_next,
				botao_sel     => botao_sel,
            resposta      => resposta
            ligado        => ligado,
				perdeu 		  => s_perdeu,
				tocar1        => s_tocar1,
				tocar2        => s_tocar2,
            db_estado     => db_estado
        );

    FD : fd_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
				tocar1  		  => s_tocar1,
				tocar2 		  => s_tocar2,
            display0      => display0,
            display1      => display1,
            display2      => display2,
            display3      => display3,
				rgb 			  => gbr
            db_tempo      => db_tempo
        );

    estimulo <= s_estimulo;

    pulso <= s_estimulo and (not resposta);

end architecture;
