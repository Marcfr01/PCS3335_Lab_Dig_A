library ieee;
use ieee.std_logic_1164.all;

entity jogo_reacao is
    port (
        clock    		: in  std_logic;
        reset    		: in  std_logic;
        jogar    		: in  std_logic;
		  botao_next   : in  std_logic;
		  botao_sel    : in  std_logic;
		  errou        : in  std_logic;
		  retry        : in  std_logic;
        display0 		: out std_logic_vector(6 downto 0);
        display1 		: out std_logic_vector(6 downto 0);
        display2 		: out std_logic_vector(6 downto 0);
        display3 		: out std_logic_vector(6 downto 0);
        ligado   		: out std_logic;
        perdeu   		: out std_logic;
        pronto   		: out std_logic;
		  gbr          : out std_logic_vector(2 downto 0);
		  num_musica   : out std_logic_vector(6 downto 0);
        db_estado 	: out std_logic_vector(6 downto 0)
        --db_tempo  	: out std_logic_vector(15 downto 0)
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
			  errou			 : in  std_logic;
			  retry         : in  std_logic;
			  fim1          : in  std_logic;
			  fim2          : in  std_logic;
			  notou         : in  std_logic;
			  incr1         : out std_logic;   
			  incr2         : out std_logic;
			  resetP1       : out std_logic;
			  resetP2       : out std_logic;	  
			  ligado        : out std_logic;
			  perdeu        : out std_logic;
			  tocar1        : out std_logic;
			  tocar2        : out std_logic;
			  pronto        : out std_logic;
			  enableCont    : out std_logic;
			  resetCont     : out std_logic;
			  num_musica    : out std_logic_vector(3 downto 0);
			  db_estado     : out std_logic_vector(3 downto 0)
        );
    end component;

    component fd_jogo_reacao is
        port (
			  clock         : in  std_logic;
			  reset         : in  std_logic;
			  tocar1        : in  std_logic;
			  incr1         : in  std_logic;
			  resetP1       : in  std_logic;
			  tocar2        : in  std_logic;
			  incr2         : in  std_logic;
			  resetP2       : in  std_logic;
			  enableCont    : in  std_logic;
			  resetCont     : in  std_logic;
			  notou         : out std_logic;
			  fim1          : out std_logic;
			  fim2          : out std_logic;
			  display0      : out std_logic_vector(6 downto 0);
			  display1      : out std_logic_vector(6 downto 0);
			  display2      : out std_logic_vector(6 downto 0);
			  display3      : out std_logic_vector(6 downto 0);
			  rgb           : out std_logic_vector(2 downto 0);
			  db_tempo      : out std_logic_vector(15 downto 0)
        );
    end component;
	 
	 component hex7seg is
        port (
            hex     : in  std_logic_vector(3 downto 0);
            display : out std_logic_vector(6 downto 0)
        );
    end component;
	 
	 signal s_perdeu        : std_logic;
	 signal s_tocar1, s_tocar2  : std_logic;
	 signal s_fim1, s_fim2  : std_logic;
	 signal db_estado3, num_musica3      : std_logic_vector(3 downto 0);
	 
	 signal s_notou, s_incr1, s_incr2, s_resetP1, s_resetP2, s_enableCont, s_resetCont : std_logic;

begin

    UC : uc_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
            jogar         => jogar,
				botao_next    => botao_next,
				botao_sel     => botao_sel,
				errou         => errou,
				retry         => retry,
				fim1          => s_fim1,
				fim2          => s_fim2,
				notou         => s_notou,
			   incr1         => s_incr1,   
			   incr2         => s_incr2,
			   resetP1       => s_resetP1,
			   resetP2       => s_resetP2,
            ligado        => ligado,
				perdeu 		  => s_perdeu,
				tocar1        => s_tocar1,
				tocar2        => s_tocar2,
				pronto        => pronto,
				enableCont    => s_enableCont,
				resetCont     => s_resetCont,
				num_musica    => num_musica3,
            db_estado     => db_estado3
        );

    FD : fd_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
				tocar1  		  => s_tocar1,
				incr1         => s_incr1,
				resetP1       => s_resetP1,
				tocar2 		  => s_tocar2,
				incr2         => s_incr2,
				resetP2       => s_resetP2,
				enableCont    => s_enableCont,
				resetCont     => s_resetCont,
				notou         => s_notou,
				fim1          => s_fim1,
				fim2          => s_fim2,
            display0      => display0,
            display1      => display1,
            display2      => display2,
            display3      => display3,
				rgb 			  => gbr,
            db_tempo      => open --db_tempo
        );
		  
		   hx : hex7seg
		port map(db_estado3, db_estado);

			hx1 : hex7seg
		port map(num_musica3, num_musica);

end architecture;
