-- ====Testbench================================================================
--
--   CASO 1 – Reset e estado inicial
--   CASO 2 – Liga desativado (LIGA=0): sistema não deve medir
--   CASO 3 – Pulso curto (~5 ciclos de clock)
--   CASO 4 – Pulso mais longo (~20 ciclos de clock)
--   CASO 5 – Segunda medição consecutiva sem desligar LIGA
--   CASO 6 – Desligar e religar (LIGA vai a 0 e volta a 1)
--   CASO 7 - Contagem ultrapassa 9999, ativando o sinal de fim
--
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity medidor_largura_tb is
end entity medidor_largura_tb;

architecture simulacao of medidor_largura_tb is

    -- Declaração do componente sob teste (DUT)
    component medidor_largura is
        port (
            clock        : in  std_logic;
            reset        : in  std_logic;
            liga         : in  std_logic;
            sinal        : in  std_logic;
            display0     : out std_logic_vector(6 downto 0);
            display1     : out std_logic_vector(6 downto 0);
            display2     : out std_logic_vector(6 downto 0);
            display3     : out std_logic_vector(6 downto 0);
            db_estado    : out std_logic_vector(6 downto 0);
            pronto       : out std_logic;
            fim          : out std_logic;
            db_clock     : out std_logic;
            db_sinal     : out std_logic;
            db_zeraCont  : out std_logic;
            db_contaCont : out std_logic
        );
    end component;

    -- Parâmetros de tempo
    constant PERIODO_CLOCK : time := 1 us;  
    signal keep_simulating : std_logic := '0'; -- delimita o tempo de geração do clock

    -- Sinais de estímulo (entradas do DUT)
    signal clock_tb  : std_logic := '0';
    signal reset_tb  : std_logic := '0';
    signal liga_tb   : std_logic := '0';
    signal sinal_tb  : std_logic := '0';

    -- Sinais de observação (saídas do DUT)
    signal display0_tb     : std_logic_vector(6 downto 0);
    signal display1_tb     : std_logic_vector(6 downto 0);
    signal display2_tb     : std_logic_vector(6 downto 0);
    signal display3_tb     : std_logic_vector(6 downto 0);
    signal db_estado_tb    : std_logic_vector(6 downto 0);
    signal pronto_tb       : std_logic;
    signal fim_tb          : std_logic;
    signal db_clock_tb     : std_logic;
    signal db_sinal_tb     : std_logic;
    signal db_zeraCont_tb  : std_logic;
    signal db_contaCont_tb : std_logic;
	 
	 -- Caso de teste
	 signal caso            : integer := 0;

begin

    -- Instanciação do DUT
    DUT: medidor_largura
        port map (
            clock        => clock_tb,
            reset        => reset_tb,
            liga         => liga_tb,
            sinal        => sinal_tb,
            display0     => display0_tb,
            display1     => display1_tb,
            display2     => display2_tb,
            display3     => display3_tb,
            db_estado    => db_estado_tb,
            pronto       => pronto_tb,
            fim          => fim_tb,
            db_clock     => db_clock_tb,
            db_sinal     => db_sinal_tb,
            db_zeraCont  => db_zeraCont_tb,
            db_contaCont => db_contaCont_tb
        );

	-- Geração do clock
	clock_tb <= not clock_tb and keep_simulating after PERIODO_CLOCK / 2;
	
	process
	begin
			
		assert false report "=== Inicio da Simulacao ===" severity note;
		keep_simulating <= '1';  -- inicia geracao do sinal de clock
		
		-- CASO 1: Reset inicial
		-- Esperado: sistema vai para estado INICIAL, zeraCont=0, contaCont=0
		caso <= 1;
		reset_tb <= '1';
		liga_tb  <= '0';
		sinal_tb <= '0';
		wait for 2 * PERIODO_CLOCK;
		reset_tb <= '0';
		wait until falling_edge(clock_tb);

		-- CASO 2: LIGA=0 – sistema permanece em INICIAL
		-- Aplica pulso em SINAL sem ligar o sistema
		-- Esperado: nenhuma contagem, estado permanece INICIAL
		caso <= 2;
		sinal_tb <= '1';
		wait for 5 * PERIODO_CLOCK;
		sinal_tb <= '0';
		wait until falling_edge(clock_tb);
	
		-- CASO 3: Pulso curto (~5 ciclos)
		-- Sequência: LIGA=1 → espera PREPARA (zeraCont=1) → SINAL=1 por 5 ciclos
		-- Esperado: contagem = 5-1, PRONTO pulsa ao final
		caso <= 3;
		liga_tb  <= '1';
		wait for 3 * PERIODO_CLOCK;   -- estado LIGADO (aguarda borda do sinal)
	
		sinal_tb <= '1';              -- início do pulso → PREPARA → CONTA
		wait for 5 * PERIODO_CLOCK;   -- pulso dura 5 ciclos
		sinal_tb <= '0';              -- fim do pulso → FIM (PRONTO=1) → ESPERA
	
		wait until falling_edge(clock_tb);  -- aguarda estabilização

		-- CASO 4: Pulso mais longo (20 ciclos)
		-- Sistema em ESPERA com LIGA=1 aguarda novo pulso
		-- Esperado: contagem = 20-2, PRONTO pulsa ao final
		caso <= 4;
		sinal_tb <= '1';
		wait for 20 * PERIODO_CLOCK;
		sinal_tb <= '0';
		wait until falling_edge(clock_tb);
	
		-- CASO 5: Segunda medição consecutiva sem desligar LIGA
		-- Sistema em ESPERA; aplica novo pulso imediatamente
		-- Esperado: nova medição (contador zerado antes), resultado = 10
		caso <= 5;
      sinal_tb <= '1';
      wait for 10 * PERIODO_CLOCK;
      sinal_tb <= '0';
      wait until falling_edge(clock_tb);

      -- CASO 6: Desligar e religar o sistema
      -- LIGA vai a 0 → estado INICIAL; LIGA volta a 1 → nova medição
      -- Esperado: ao voltar LIGA=1 e aplicar SINAL, medição reinicia do zero
		caso <= 6;
      liga_tb  <= '0';
      wait for 5 * PERIODO_CLOCK;  -- deve ir para INICIAL

      liga_tb  <= '1';
      wait for 3 * PERIODO_CLOCK;  -- estado LIGADO

      sinal_tb <= '1';
      wait for 8 * PERIODO_CLOCK;
      sinal_tb <= '0';
      wait until falling_edge(clock_tb);
		
		-- CASO 7 - Contagem ultrapassa 9999, ativando o sinal de fim
		caso <= 7;
		sinal_tb <= '1';
		wait for 10004 * PERIODO_CLOCK;
		sinal_tb <= '0';
		wait until falling_edge(clock_tb);

      -- Fim da simulação
		caso <= 99;
      wait for 10 * PERIODO_CLOCK;
      report "=== Simulacao concluida com sucesso ===" severity note;
		keep_simulating <= '0';
      wait;  

	end process;

end architecture simulacao;
