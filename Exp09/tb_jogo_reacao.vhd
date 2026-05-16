-- =============================================================
-- PCS3335 - Laboratorio Digital A
-- Arquivo   : tb_jogo_reacao.vhd
-- Descricao : Testbench da interface com leds e botoes
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_jogo_reacao is
end entity tb_jogo_reacao;

architecture sim of tb_jogo_reacao is

    -- Componente sob teste
    component jogo_reacao is
        port (
			  clock    		: in  std_logic;
			  clock50      : in  std_logic;
			  reset    		: in  std_logic;
			  jogar    		: in  std_logic;
			  botao_next   : in  std_logic;
			  botao_sel    : in  std_logic;
			  retry        : in  std_logic;
			  ps2_clk     : in  std_logic;
        ps2_data    : in  std_logic;
		  
		  --Saida de pontuacao
		  pontos      : out std_logic_vector(9 downto 0);
			  display0 		: out std_logic_vector(6 downto 0);
			  display1 		: out std_logic_vector(6 downto 0);
			  display2 		: out std_logic_vector(6 downto 0);
			  display3 		: out std_logic_vector(6 downto 0);
			  ligado   		: out std_logic;
			  perdeu   		: out std_logic;
			  pronto   		: out std_logic;
			  gbr          : out std_logic_vector(2 downto 0);
			          buzz        : out std_logic;
        num_musica  : out std_logic_vector(6 downto 0);
			  db_estado 	: out std_logic_vector(6 downto 0)
			 );
    end component;

    -- Sinais de estimulo (entradas do DUT)
    signal clock_tb    : std_logic := '0';
	 signal clock50_tb  : std_logic := '0';
    signal reset_tb    : std_logic := '0';
    signal jogar_tb  : std_logic := '0';
    signal errou_tb : std_logic := '0';
	 signal retry_tb : std_logic := '0';
signal botao_next_tb : std_logic := '0';
	 signal botao_sel_tb  : std_logic := '0';
	 
	  signal ps2_clk_tb  : std_logic := '0';
     signal ps2_data_tb : std_logic := '0';

    -- Sinais de observacao (saidas do DUT)
    signal ligado_tb     : std_logic;
    signal perdeu_tb     : std_logic;
	 signal pronto_tb     : std_logic;
    signal gbr_tb        : std_logic_vector(2 downto 0);
	 signal db_estado_tb  : std_logic_vector(6 downto 0);
	 signal display0_tb   : std_logic_vector(6 downto 0);
	 signal display1_tb   : std_logic_vector(6 downto 0);
	 signal display2_tb   : std_logic_vector(6 downto 0);
	 signal display3_tb   : std_logic_vector(6 downto 0); 
	 
	 signal pontos_tb     : std_logic_vector(9 downto 0);
	 signal buzz_tb       : std_logic;
    signal num_musica_tb : std_logic_vector(6 downto 0);
	 
	 -- Indicador do caso de teste
	 signal caso : integer := 0;

    -- Controle de simulacao
    signal keep_simulating : std_logic := '1';

    -- Periodo do clock: 1ms (1 kHz)
    constant T_CLK  : time := 1 ms;
	  -- Periodo do clock: 20ns (50 MHz)
    constant T_CLK50  : time := 20 ns;
    -- Atraso apos borda para evitar setup/hold violations
    constant T_HOLD : time := 100 ns;

begin

    -- Clock: gera enquanto keep_simulating = '1'
    clock_tb <= (not clock_tb) and keep_simulating after T_CLK / 2;
	 clock50_tb <= (not clock50_tb) and keep_simulating after T_CLK50 / 2;

    -- Instancia do DUT
    DUT: jogo_reacao
        port map (
           clock    	   => clock_tb,
			  
			  clock50      => clock50_tb,
			  reset    		=> reset_tb,
			  
			  jogar    		=> jogar_tb,
			  botao_next   => botao_next_tb,
			  botao_sel    => botao_sel_tb,
			  retry        => retry_tb,
			  
			  ps2_clk     => ps2_clk_tb,
        ps2_data       => ps2_data_tb,       
		  pontos         => pontos_tb,
		  
			  display0 		=> display0_tb,
			  display1 		=> display1_tb,
			  display2 		=> display2_tb,
			  display3 		=> display3_tb,
			  ligado   		=> ligado_tb,
			  perdeu   		=> perdeu_tb,
			  pronto   		=> pronto_tb,
			  gbr          => gbr_tb,
			  
			          buzz        => buzz_tb,
        num_musica  => num_musica_tb,  
		  
			  db_estado 	=> db_estado_tb
        );

    -- Processo de estimulacao
    process
        -- Espera N bordas de subida do clock
        procedure wait_clocks(n : integer) is
        begin
            for i in 1 to n loop
                wait until rising_edge(clock_tb);
            end loop;
            wait for T_HOLD;
        end procedure;

    begin

        -- ======================================================
        -- TC1: Reset no estado INICIAL
        -- ======================================================
        report "=== TC1: Reset no estado INICIAL ===" severity note;
		  
		  caso <= 1;

        reset_tb   <= '1';
        jogar_tb <= '0';
        wait_clocks(3);
        reset_tb <= '0';
        wait_clocks(2);

        report "TC1: PASS" severity note;

        -- ======================================================
        -- TC2: INICIAL -> MUSICA1
        -- ======================================================
        report "=== TC2: INICIAL -> MUSICA1 ===" severity note;
		  
		  caso <= 2;

        jogar_tb <= '1';
        wait_clocks(1);
        jogar_tb <= '0';
        wait_clocks(1);

        report "TC2: PASS" severity note;

        -- Volta ao INICIAL para o proximo caso
        reset_tb <= '1';
        wait_clocks(2);
        reset_tb <= '0';
        wait_clocks(1);

        -- ======================================================
        -- TC3: INICIAL -> MUSICA1 -> MUSICA2
        -- ======================================================
        report "=== TC3: INICIAL -> MUSICA1 -> MUSICA2 ===" severity note;
		  
		  caso <= 3;

        jogar_tb  <= '1';
        wait_clocks(1);
        jogar_tb <= '0';
		  wait_clocks(2);

		  botao_next_tb <= '1';
		  wait_clocks(3);
		  botao_next_tb <= '0';

        report "TC3: PASS" severity note;

        -- Volta ao INICIAL
        reset_tb <= '1';
        wait_clocks(2);
        reset_tb <= '0';
        wait_clocks(1);

        -- ======================================================
        -- TC4: INICIAL -> MUSICA1 -> MUSICA2 -> MUSICA1
        -- ======================================================
        report "=== TC4: INICIAL -> MUSICA1 -> MUSICA2 -> MUSICA1 ===" severity note;
		  
		  caso <= 4;

        jogar_tb  <= '1';
        wait_clocks(1);
        jogar_tb <= '0';
        wait_clocks(3);   

        botao_next_tb <= '1';
		  wait_clocks(3);
		  botao_next_tb <= '0';
		  wait_clocks(2);
		  
		   botao_next_tb <= '1';
		  wait_clocks(3);
		  botao_next_tb <= '0';

        report "TC4: PASS" severity note;

        -- ======================================================
        -- TC5: MUSICA1 -> JOGA1 -> FIM
        -- ======================================================
        report "=== TC5: MUSICA1 -> JOGA1 -> FIM ===" severity note;
		  
		  caso <= 5;
			
		  wait_clocks(1);
        botao_sel_tb <= '1';
		  wait_clocks(3);
		  botao_sel_tb <= '0';
        
        wait until pronto_tb = '1';
        wait_clocks(3);   

        report "TC5: PASS" severity note;

        -- ======================================================
        -- TC6: FIM -> MUSICA1
        -- ======================================================
        report "=== TC6: FIM -> MUSICA1 ===" severity note;
		  
		  caso <= 6;

        retry_tb <= '1';   
        wait_clocks(3);
		  retry_tb <= '0';

        report "TC6: PASS - retornou ao INICIAL" severity note;

		  -- ======================================================
        -- TC7: MUSICA1 -> MUSICA2 -> JOGA2 -> FIM
        -- ======================================================
        report "=== TC7: MUSICA1 -> MUSICA2 -> JOGA2 -> FIM ===" severity note;
		  
		  caso <= 7;
		
		  wait_clocks(1);
        botao_next_tb <= '1';
		  wait_clocks(3);
		  botao_next_tb <= '0';
		  wait_clocks(2);
		  
		  botao_sel_tb <= '1';
		  wait_clocks(3);
		  botao_sel_tb <= '0';

        wait until pronto_tb = '1';
        wait_clocks(3);  

        report "TC7: PASS" severity note;
		  
		  
		  -- ======================================================
        -- TC8: FIM -> MUSICA1 -> JOGA1 -> PERDE
        -- ======================================================
        report "=== TC8: FIM -> MUSICA1 -> JOGA1 -> PERDE ===" severity note;
		  
		  caso <= 8;

        retry_tb <= '1';   
        wait_clocks(3);
		  retry_tb <= '0';
			
		  botao_sel_tb <= '1';
		  wait_clocks(3);
		  botao_sel_tb <= '0';
		  
		  wait_clocks(15);
		  
		  --errou_tb <= '1';
		  --wait_clocks(3);

        report "TC8: PASS" severity note;
		  
        -- ======================================================
        -- TC9: FIM -> MUSICA1 -> MUSICA2 -> JOGA2 -> PERDE
        -- ======================================================
        report "=== TC9: FIM -> MUSICA1 -> MUSICA2 -> JOGA2 -> PERDE ===" severity note;
		  
		  caso <= 9;

        retry_tb <= '1';   
        wait_clocks(3);
		  retry_tb <= '0';
		
		  botao_next_tb <= '1';
		  wait_clocks(3);
		  botao_next_tb <= '0';
		  wait_clocks(2);
		  
		  botao_sel_tb <= '1';
		  wait_clocks(3);
		  botao_sel_tb <= '0';
		  
		  wait_clocks(15);
		  
		  --errou_tb <= '1';
		  --wait_clocks(3);
		  
        report "TC9: PASS" severity note;

        -- ======================================================
        -- FIM DA SIMULACAO
        -- ======================================================
		  
		  caso <= 99;
		  
        reset_tb <= '1';
        wait_clocks(2);
        reset_tb <= '0';

        report "=== SIMULACAO CONCLUIDA ===" severity note;
        keep_simulating <= '0';
        wait;

    end process;

end architecture sim;
