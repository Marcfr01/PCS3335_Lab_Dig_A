-- =============================================================
-- PCS3335 - Laboratorio Digital A
-- Arquivo   : tb_interface_leds_botoes.vhd
-- Descricao : Testbench da interface com leds e botoes
--
-- Casos de teste:
--   TC1 - Reset no estado INICIAL
--   TC2 - INICIAL -> PREPARA (iniciar=1)
--   TC3 - PREPARA -> ESTIMULA (passou10=1, resposta=0)
--   TC4 - PREPARA -> ERROR   (resposta=1 durante espera)
--   TC5 - ESTIMULA -> FIM    (resposta=1 apos estimulo)
--   TC6 - FIM -> ESPERA      (resposta=1 no estado FIM)
--   TC7 - Contagem longa: contador ultrapassa MODULO (RCO cicla)
-- =============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_interface_leds_botoes is
end entity tb_interface_leds_botoes;

architecture sim of tb_interface_leds_botoes is

    -- Componente sob teste
    component interface_leds_botoes is
        port (
            clock     : in  std_logic;
            reset     : in  std_logic;
            iniciar   : in  std_logic;
            resposta  : in  std_logic;
            ligado    : out std_logic;
            estimulo  : out std_logic;
            pulso     : out std_logic;
            erro      : out std_logic;
            pronto    : out std_logic;
				db_estado : out std_logic_vector(3 downto 0)
        );
    end component;

    -- Sinais de estimulo (entradas do DUT)
    signal clock_tb    : std_logic := '0';
    signal reset_tb    : std_logic := '0';
    signal iniciar_tb  : std_logic := '0';
    signal resposta_tb : std_logic := '0';

    -- Sinais de observacao (saidas do DUT)
    signal ligado_tb    : std_logic;
    signal estimulo_tb  : std_logic;
    signal pulso_tb     : std_logic;
    signal erro_tb      : std_logic;
    signal pronto_tb    : std_logic;
	 signal db_estado_tb : std_logic_vector(3 downto 0);
	 
	 -- Indicador do caso de teste
	 signal caso : integer := 0;

    -- Controle de simulacao
    signal keep_simulating : std_logic := '1';

    -- Periodo do clock: 20 ns (50 MHz)
    constant T_CLK  : time := 20 ns;
    -- Atraso apos borda para evitar setup/hold violations
    constant T_HOLD : time := 2 ns;

begin

    -- Clock: gera enquanto keep_simulating = '1'
    clock_tb <= (not clock_tb) and keep_simulating after T_CLK / 2;

    -- Instancia do DUT
    DUT: interface_leds_botoes
        port map (
            clock     => clock_tb,
            reset     => reset_tb,
            iniciar   => iniciar_tb,
            resposta  => resposta_tb,
            ligado    => ligado_tb,
            estimulo  => estimulo_tb,
            pulso     => pulso_tb,
            erro      => erro_tb,
            pronto    => pronto_tb,
				db_estado => db_estado_tb
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
        iniciar_tb <= '0';
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
        -- Condicao: iniciar=1 por 1 ciclo
        -- Esperado: ligado=1, estimulo=0, erro=0
        -- ======================================================
        report "=== TC2: INICIAL -> PREPARA ===" severity note;
		  
		  caso <= 2;

        iniciar_tb <= '1';
        wait_clocks(1);
        iniciar_tb <= '0';
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
        report "=== TC3: PREPARA -> ESTIMULA (10000 clocks) ===" severity note;
		  
		  caso <= 3;

        iniciar_tb  <= '1';
        resposta_tb <= '0';
        wait_clocks(1);
        iniciar_tb <= '0';

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

        iniciar_tb  <= '1';
        resposta_tb <= '0';
        wait_clocks(1);
        iniciar_tb <= '0';
        wait_clocks(3);   -- alguns ciclos dentro de PREPARA, antes do estimulo

        resposta_tb <= '1';   -- jogada invalida
        wait_clocks(1);

        assert erro_tb     = '1' report "TC4 FAIL: erro deve ser 1"            severity error;
        assert estimulo_tb = '0' report "TC4 FAIL: estimulo deve ser 0"        severity error;
        assert ligado_tb   = '0' report "TC4 FAIL: ligado deve ser 0 em ERROR" severity error;
        report "TC4: PASS" severity note;

        -- Libera resposta -> FSM volta ao INICIAL
        resposta_tb <= '0';
        wait_clocks(2);

        -- ======================================================
        -- TC5: ESTIMULA -> FIM
        -- Condicao: chegar a ESTIMULA e acionar resposta=1
        -- Esperado: pronto=1, estimulo=0
        -- ======================================================
        report "=== TC5: ESTIMULA -> FIM ===" severity note;
		  
		  caso <= 5;

        iniciar_tb  <= '1';
        resposta_tb <= '0';
        wait_clocks(1);
        iniciar_tb <= '0';

        wait until estimulo_tb = '1';
        wait_clocks(2);   -- permanece alguns ciclos em ESTIMULA

        resposta_tb <= '1';   -- jogador responde
        wait_clocks(1);

        assert pronto_tb   = '1' report "TC5 FAIL: pronto deve ser 1 em FIM"  severity error;
        assert estimulo_tb = '0' report "TC5 FAIL: estimulo deve cair em FIM" severity error;
        report "TC5: PASS" severity note;

        -- ======================================================
        -- TC6: FIM -> ESPERA
        -- Condicao: manter resposta=1 no estado FIM
        -- Esperado: ligado=1, pronto=0
        --           ao soltar resposta, volta ao INICIAL
        -- ======================================================
        report "=== TC6: FIM -> ESPERA ===" severity note;
		  
		  caso <= 6;

        -- resposta ainda esta em '1' (vindo do TC5), forcando FIM -> ESPERA
        wait_clocks(1);

        assert pronto_tb = '0' report "TC6 FAIL: pronto deve ser 0 em ESPERA" severity error;
        assert ligado_tb = '1' report "TC6 FAIL: ligado deve ser 1 em ESPERA" severity error;
        report "TC6: PASS - em ESPERA com resposta=1" severity note;

        resposta_tb <= '0';   -- solta resposta -> volta ao INICIAL
        wait_clocks(2);

        assert ligado_tb = '0' report "TC6 FAIL: deve voltar ao INICIAL" severity error;
        report "TC6: PASS - retornou ao INICIAL" severity note;

        -- ======================================================
        -- TC7: Contagem longa - contador ultrapassa MODULO
        -- Condicao: entrar em PREPARA e aguardar mais de 10000
        --           ciclos; verificar que o RCO cicla e o
        --           circuito avanca para ESTIMULA corretamente.
        --           Em seguida, permanece em ESTIMULA por mais
        --           de 10000 ciclos para garantir que o contador
        --           ciclando nao perturba o estado da FSM.
        -- Esperado: estimulo=1 e circuito estavel em ESTIMULA
        -- ======================================================
        report "=== TC7: Contagem longa (contador ultrapassa MODULO) ===" severity note;
		  
		  caso <= 7;

        iniciar_tb  <= '1';
        resposta_tb <= '0';
        wait_clocks(1);
        iniciar_tb <= '0';

        -- Aguarda primeiro passou10 -> transicao para ESTIMULA
        wait until estimulo_tb = '1';
        report "TC7: estimulo ativado apos primeira contagem completa" severity note;

        -- Permanece em ESTIMULA por mais de 10000 ciclos
        -- (verifica que o contador ciclando nao altera a FSM)
        wait_clocks(10005);

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
