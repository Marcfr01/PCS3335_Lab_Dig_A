library ieee;
use ieee.std_logic_1164.all;

entity jogo_reacao is
    port (
        clock       : in  std_logic;
		  clock50     : in  std_logic;
		  butao       : in std_logic;
        reset       : in  std_logic;
        jogar       : in  std_logic;
        botao_next  : in  std_logic;
        botao_sel   : in  std_logic;
        retry       : in  std_logic;
 
        -- Barramento PS/2
        ps2_clk     : in  std_logic;
        ps2_data    : in  std_logic;
		  
		  --Saida de pontuacao
		  --pontos      : out std_logic_vector(9 downto 0);
 
        -- Saidas originais
        display0    : out std_logic_vector(6 downto 0);
        display1    : out std_logic_vector(6 downto 0);
        display2    : out std_logic_vector(6 downto 0);
        display3    : out std_logic_vector(6 downto 0);
        ligado      : out std_logic;
        perdeu      : out std_logic;
        pronto      : out std_logic;
        gbr         : out std_logic_vector(2 downto 0);
        buzz        : out std_logic;
        num_musica  : out std_logic_vector(6 downto 0);
        db_estado   : out std_logic_vector(6 downto 0)
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
            retry         : in  std_logic;
            fim1          : in  std_logic;
            fim2          : in  std_logic;
            notou         : in  std_logic;
            passou05      : in  std_logic;
            --resposta      : in  std_logic_vector(6 downto 0);
            --nota_atual    : in  std_logic_vector(6 downto 0);
				acertou       : in  std_logic;
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
            somarPts      : out std_logic;
				zerarPts      : out std_logic;
            ledar         : out std_logic;
            num_musica    : out std_logic_vector(3 downto 0);
            db_estado     : out std_logic_vector(3 downto 0)
        );
    end component;
 
    component fd_jogo_reacao is
        port (
            clock         : in  std_logic;
            reset         : in  std_logic;
				butao         : in std_logic;
				clock50       : in  std_logic;
				ledar         : in  std_logic;
				ps2_clk       : in  std_logic;
            ps2_data      : in  std_logic;
            tocar1        : in  std_logic;
            incr1         : in  std_logic;
            resetP1       : in  std_logic;
            tocar2        : in  std_logic;
            incr2         : in  std_logic;
            resetP2       : in  std_logic;
            enableCont    : in  std_logic;
            resetCont     : in  std_logic;
            somarPts      : in  std_logic;
				zerarPts      : in  std_logic;
            notou         : out std_logic;
				passou05      : out std_logic;
				fim1          : out std_logic;
            fim2          : out std_logic;
            --resposta      : out std_logic_vector(6 downto 0);
            --nota_atual    : out std_logic_vector(6 downto 0);
				acertou       :out std_logic;
            display0      : out std_logic_vector(6 downto 0);
            display1      : out std_logic_vector(6 downto 0);
            display2      : out std_logic_vector(6 downto 0);
            display3      : out std_logic_vector(6 downto 0);
            rgb           : out std_logic_vector(2 downto 0);
            buzz          : out std_logic;
				
				pontos       : out std_logic_vector(9 downto 0);
            
				db_tempo      : out std_logic_vector(15 downto 0)
        );
    end component;
 
    component hex7seg is
        port (
            hex     : in  std_logic_vector(3 downto 0);
            display : out std_logic_vector(6 downto 0)
        );
    end component;
	 
	 component Bin_to_7Seg is
    Port ( 
        bin_in : in  std_logic_vector (9 downto 0); -- Entrada binária (máx 1023)
        seg3   : out std_logic_vector (6 downto 0); -- Display dos Milhares (0 ou 1)
        seg2   : out std_logic_vector (6 downto 0); -- Display das Centenas
        seg1   : out std_logic_vector (6 downto 0); -- Display das Dezenas
        seg0   : out std_logic_vector (6 downto 0)  -- Display das Unidades
    );
end component;


	 
	 signal s_perdeu        : std_logic;
	 signal s_pontos        : std_logic_vector(9 downto 0);
	 signal s_tocar1, s_tocar2  : std_logic;
	 signal s_fim1, s_fim2  : std_logic;
	 signal db_estado3, num_musica3      : std_logic_vector(3 downto 0);
	 
	 signal s_notou, s_incr1, s_incr2, s_resetP1, s_resetP2, s_enableCont, s_resetCont : std_logic;
	 
	 signal s_somarPts, s_zerarPts    : std_logic;
    signal s_ledar                   : std_logic;  -- nao exposto externamente
    signal s_passou05                : std_logic := '0';  -- TODO: ligar a contador de 500ms
 
    -- Teclado PS/2
    --signal s_resposta   : std_logic_vector(6 downto 0);
 
    -- Nota sendo tocada (one-hot, extraida do FD)
    --signal s_nota_atual : std_logic_vector(6 downto 0);
	 signal s_acertou    : std_logic;

begin

    UC : uc_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
            jogar         => jogar,
            botao_next    => botao_next,
            botao_sel     => botao_sel,
            retry         => retry,
            fim1          => s_fim1,
            fim2          => s_fim2,
            notou         => s_notou,
            passou05      => s_passou05,
            --resposta      => s_resposta,
            --nota_atual    => s_nota_atual,
				acertou       => s_acertou,
            incr1         => s_incr1,
            incr2         => s_incr2,
            resetP1       => s_resetP1,
            resetP2       => s_resetP2,
            ligado        => ligado,
            perdeu        => perdeu,
            tocar1        => s_tocar1,
            tocar2        => s_tocar2,
            pronto        => pronto,
            enableCont    => s_enableCont,
            resetCont     => s_resetCont,
            somarPts      => s_somarPts,
				zerarPts      => s_zerarPts,
            ledar         => s_ledar,
            num_musica    => num_musica3,
            db_estado     => db_estado3
        );

    FD : fd_jogo_reacao
        port map (
            clock         => clock,
            reset         => reset,
				butao      => butao,
				clock50       => clock50,
				ledar         => s_ledar,
            ps2_clk       => ps2_clk,
            ps2_data      => ps2_data,
            tocar1        => s_tocar1,
            incr1         => s_incr1,
            resetP1       => s_resetP1,
            tocar2        => s_tocar2,
            incr2         => s_incr2,
            resetP2       => s_resetP2,
            enableCont    => s_enableCont,
            resetCont     => s_resetCont,
            somarPts      => s_somarPts,
				zerarPts      => s_zerarPts,
            notou         => s_notou,
				passou05      => s_passou05,
            fim1          => s_fim1,
            fim2          => s_fim2,
				acertou       => s_acertou,
            --resposta      => s_resposta,
            --nota_atual    => s_nota_atual,
            display0      => display0,
            display1      => display1,
            display2      => display2,
            display3      => display3,
            rgb           => gbr,
            buzz          => buzz,
				pontos        => s_pontos,
            db_tempo      => open
        );
		  
		   hx : hex7seg
		port map(db_estado3, db_estado);

			hx1 : hex7seg
		port map(num_musica3, num_musica);
		
		--Pontososos : Bin_to_7Seg
		--port map(s_pontos, display3, display2, display1, display0);
		
		

end architecture;
