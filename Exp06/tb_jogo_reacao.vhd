-- =============================================================
-- PCS3335 - Laboratorio Digital A
-- Arquivo   : tb_jogo_reacao.vhd
-- Descricao : Testbench da interface com leds e botoes
--
-- Casos de teste:
--   TC1 - Reset no estado INICIAL
--   TC2 - INICIAL -> PREPARA (jogar=1)
--   TC3 - PREPARA -> ESTIMULA (passou10=1, resposta=0)
--   TC4 - PREPARA -> ERROR   (resposta=1 durante espera)
--   TC5 - ESTIMULA -> FIM    (resposta=1 apos estimulo)
--   TC6 - FIM -> ESPERA      (resposta=1 no estado FIM)
--   TC7 - Contagem longa: contador ultrapassa MODULO (RCO cicla)
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
    end component;

    -- Sinais de estimulo (entradas do DUT)
    signal clock_tb    : std_logic := '0';
    signal reset_tb    : std_logic := '0';
    signal jogar_tb  : std_logic := '0';
    signal resposta_tb : std_logic := '0';

    -- Sinais de observacao (saidas do DUT)
    signal ligado_tb    : std_logic;
    signal estimulo_tb  : std_logic;
    signal pulso_tb     : std_logic;
    signal erro_tb      : std_logic;
    signal pronto_tb    : std_logic;
	 signal db_estado_tb : std_logic_vector(3 downto 0);
	 signal db_tempo_tb  : std_logic_vector(15 downto 0);
	 signal display0_tb  : std_logic_vector(6 downto 0);
	 signal display1_tb  : std_logic_vector(6 downto 0);
	 signal display2_tb  : std_logic_vector(6 downto 0);
	 signal display3_tb  : std_logic_vector(6 downto 0);
	 
	 -- Indicador do caso de teste
	 signal caso : integer := 0;

    -- Controle de simulacao
    signal keep_simulating : std_logic := '1';

    -- Periodo do clock: 20 ns (1 kHz)
    constant T_CLK  : time := 1 us;
    -- Atraso apos borda para evitar setup/hold violations
    constant T_HOLD : time := 100 ns;

begin

    -- Clock: gera enquanto keep_simulating = '1'
    clock_tb <= (not clock_tb) and keep_simulating after T_CLK / 2;

    -- Instancia do DUT
    DUT: jogo_reacao
        port map (
            clock     => clock_tb,
            reset     => reset_tb,
            jogar     => jogar_tb,
            resposta  => resposta_tb,
				display0  => display0_tb,
				display1  => display1_tb,
				display2  => display2_tb,
				display3  => display3_tb,
            ligado    => ligado_tb,
            pulso     => pulso_tb,
            estimulo  => estimulo_tb,
            erro      => erro_tb,
            pronto    => pronto_tb,
				db_estado => db_estado_tb,
				db_tempo  => db_tempo_tb
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
        -- Esperado: todas as saidas em '0'
        -- ======================================================
        report "=== TC1: Reset no estado INICIAL ===" severity note;
		  
		  caso <= 1;

        reset_tb   <= '1';
        jogar_tb <= '0';
        wait_clocks(3);
        reset_tb <= '0';
        wait_clocks(2);

        assert ligado_tb   = '0' report "TC1 FAIL: ligado deve ser 0"   severity error;
        assert estimulo_tb = '0' report "TC1 FAIL: estimulo deve ser 0" severity error;
        assert erro_tb     = '0' report "TC1 FAIL: erro deve ser 0"     severity error;
        assert pronto_tb   = '0' report "TC1 FAIL: pronto deve ser 0"   severity error;
        report "TC1: PASS" severity note;

        -- ======================================================
        -- TC2: INICIAL -> PREPARA
        -- Condicao: jogar=1 por 1 ciclo
        -- Esperado: ligado=1, estimulo=0, erro=0
        -- ======================================================
        report "=== TC2: INICIAL -> PREPARA ===" severity note;
		  
		  caso <= 2;

        jogar_tb <= '1';
        wait_clocks(1);
        jogar_tb <= '0';
        wait_clocks(1);

        assert ligado_tb   = '1' report "TC2 FAIL: ligado deve ser 1 em PREPARA"   severity error;
        assert estimulo_tb = '0' report "TC2 FAIL: estimulo deve ser 0 em PREPARA" severity error;
        assert erro_tb     = '0' report "TC2 FAIL: erro deve ser 0"                severity error;
        report "TC2: PASS" severity note;

        -- Volta ao INICIAL para o proximo caso
        reset_tb <= '1';
        wait_clocks(2);
        reset_tb <= '0';
        wait_clocks(1);

        -- ======================================================
        -- TC3: PREPARA -> ESTIMULA
        -- Condicao: entrar em PREPARA e aguardar os 10000 ciclos
        --           do contador (MODULO=10000) com resposta=0
        -- Esperado: estimulo=1, ligado=1, erro=0
        -- ======================================================
        report "=== TC3: PREPARA -> ESTIMULA (5000 clocks) ===" severity note;
		  
		  caso <= 3;

        jogar_tb  <= '1';
        resposta_tb <= '0';
        wait_clocks(1);
        jogar_tb <= '0';

        wait until estimulo_tb = '1';
        wait for T_HOLD;

        assert estimulo_tb = '1' report "TC3 FAIL: estimulo deve ser 1" severity error;
        assert ligado_tb   = '1' report "TC3 FAIL: ligado deve ser 1"   severity error;
        assert erro_tb     = '0' report "TC3 FAIL: erro nao deve subir" severity error;
        report "TC3: PASS" severity note;

        -- Volta ao INICIAL
        reset_tb <= '1';
        wait_clocks(2);
        reset_tb <= '0';
        wait_clocks(1);

        -- ======================================================
        -- TC4: PREPARA -> ERROR
        -- Condicao: entrar em PREPARA e acionar resposta=1
        --           antes de passou10
        -- Esperado: erro=1, estimulo=0, ligado=0
        -- ======================================================
        report "=== TC4: PREPARA -> ERROR ===" severity note;
		  
		  caso <= 4;

        jogar_tb  <= '1';
        resposta_tb <= '0';
        wait_clocks(1);
        jogar_tb <= '0';
        wait_clocks(3);   -- alguns ciclos dentro de PREPARA, antes do estimulo

        resposta_tb <= '1';   -- jogada invalida
        wait_clocks(1);

        assert erro_tb     = '1' report "TC4 FAIL: erro deve ser 1"            severity error;
        assert estimulo_tb = '0' report "TC4 FAIL: estimulo deve ser 0"        severity error;
        assert ligado_tb   = '0' report "TC4 FAIL: ligado deve ser 0 em ERROR" severity error;
		  assert display0_tb = "0010000" report "TC4 FAIL: display0 deve ser 9_10 em ERROR" severity error;
		  assert display1_tb = "0010000" report "TC4 FAIL: display1 deve ser 9_10 em ERROR" severity error;
		  assert display2_tb = "0010000" report "TC4 FAIL: display2 deve ser 9_10 em ERROR" severity error;
		  assert display3_tb = "0010000" report "TC4 FAIL: display3 deve ser 9_10 em ERROR" severity error;
        report "TC4: PASS" severity note;

        -- Libera resposta -> FSM volta ao INICIAL
        resposta_tb <= '0';
        wait_clocks(2);

        -- ======================================================
        -- TC5: ESTIMULA -> MEDE -> FIM
        -- Condicao: chegar a ESTIMULA e acionar resposta=1
        -- Esperado: pronto=1, estimulo=0
        -- ======================================================
        report "=== TC5: ESTIMULA -> FIM ===" severity note;
		  
		  caso <= 5;

        jogar_tb  <= '1';
        resposta_tb <= '0';
        wait_clocks(1);
        jogar_tb <= '0';

        wait until estimulo_tb = '1';
        wait_clocks(15);   -- permanece alguns ciclos em ESTIMULA

        resposta_tb <= '1';   -- jogador responde
        wait_clocks(1);

        assert pronto_tb   = '1' report "TC5 FAIL: pronto deve ser 1 em FIM"  severity error;
        assert estimulo_tb = '0' report "TC5 FAIL: estimulo deve cair em FIM" severity error;
        report "TC5: PASS" severity note;

        -- ======================================================
        -- TC6: FIM -> ESPERA
        -- Condicao: manter resposta=1 no estado FIM
        -- Esperado: ligado=1, pronto=1
        --           ao soltar resposta, volta ao INICIAL
        -- ======================================================
        report "=== TC6: FIM -> ESPERA ===" severity note;
		  
		  caso <= 6;

        -- resposta ainda esta em '1' (vindo do TC5), forcando FIM -> ESPERA
        wait_clocks(1);

        assert pronto_tb = '1' report "TC6 FAIL: pronto deve ser 1 em ESPERA" severity error;
        assert ligado_tb = '1' report "TC6 FAIL: ligado deve ser 1 em ESPERA" severity error;
        report "TC6: PASS - em ESPERA com resposta=1" severity note;

        resposta_tb <= '0';   -- solta resposta -> volta ao INICIAL
        wait_clocks(2);

        assert ligado_tb = '0' report "TC6 FAIL: deve voltar ao INICIAL" severity error;
        report "TC6: PASS - retornou ao INICIAL" severity note;

        -- ======================================================
        -- TC7: Contagem longa - contador ultrapassa MODULO
        -- Condicao: entrar em PREPARA e aguardar mais de 5000
        --           ciclos; verificar que o RCO cicla e o
        --           circuito avanca para ESTIMULA corretamente.
        --           Em seguida, permanece em ESTIMULA por mais
        --           de 5000 ciclos para garantir que o contador
        --           ciclando nao perturba o estado da FSM.
        -- Esperado: estimulo=1 e circuito estavel em ESTIMULA
        -- ======================================================
        report "=== TC7: Contagem longa (contador ultrapassa MODULO) ===" severity note;
		  
		  caso <= 7;

        jogar_tb  <= '1';
        resposta_tb <= '0';
        wait_clocks(1);
        jogar_tb <= '0';

        -- Aguarda primeiro passou10 -> transicao para ESTIMULA
        wait until estimulo_tb = '1';
        report "TC7: estimulo ativado apos primeira contagem completa" severity note;

        -- Permanece em ESTIMULA por mais de 10000 ciclos
        -- (verifica que o contador ciclando nao altera a FSM)
        wait_clocks(5050);

        assert estimulo_tb = '1' report "TC7 FAIL: estimulo deve permanecer em 1" severity error;
        assert ligado_tb   = '1' report "TC7 FAIL: ligado deve permanecer em 1"   severity error;
        assert erro_tb     = '0' report "TC7 FAIL: erro nao deve subir"           severity error;
        report "TC7: PASS - circuito estavel apos contagem longa" severity note;

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
