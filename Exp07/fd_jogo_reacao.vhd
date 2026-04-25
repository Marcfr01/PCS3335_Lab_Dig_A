-------------------------------------------------------------------------------
-- Arquivo   : fd_jogo_reacao.vhd
-- Descricao : Fluxo de Dados do Jogo do Tempo de Reacao
--             Extensoes A2 e B1
--
-- Canal A (clr_espera / contar_espera):
--   Ativo em PREPARA e PREPARA2.
--   passou_rand   = Canal_A >= N_rand  (A2: tempo aleatorio sem alarme falso)
--   passou_falso  = Canal_A >= M_rand  (B1: tempo p/ disparar alarme falso)
--   passou_metade = Canal_A >= M_rand/2 (B1: tempo p/ estimulo real pos-alarme)
--   Como clr_espera='1' em FALSO_ALARME (assicrono), ao entrar em PREPARA2
--   o Canal A comeca do zero automaticamente.
--
-- Canal B (clr_falso / contar_falso):
--   Ativo apenas em FALSO_ALARME.
--   passou_2s = Canal_B >= 2  (2 segundos fixos de alarme falso)
--
-- LFSR_A -> N_rand: tempo de espera em PREPARA quando nao ha alarme falso
-- LFSR_B -> M_rand: define se ha alarme falso (impar) e qual o tempo de espera
--   tem_falso = LSB de M_rand ('1' se impar)
--   metade_b  = floor(M_rand/2), minimo 1 segundo
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fd_jogo_reacao is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        -- Controle da fase PREPARA / PREPARA2 (Canal A)
        clr_espera    : in  std_logic;
        contar_espera : in  std_logic;
        -- Controle da fase FALSO_ALARME (Canal B)
        clr_falso     : in  std_logic;
        contar_falso  : in  std_logic;
        -- Controle da medicao de tempo de reacao
        clr_tempo     : in  std_logic;
        contar_tempo  : in  std_logic;
        sel_erro      : in  std_logic;
        -- Condicoes de tempo para a UC
        passou_rand   : out std_logic;   -- A2: N_rand s em PREPARA (sem alarme)
        passou_falso  : out std_logic;   -- B1: M_rand s em PREPARA (com alarme)
        passou_2s     : out std_logic;   -- B1: 2 s fixos em FALSO_ALARME
        passou_metade : out std_logic;   -- B1: M_rand/2 s em PREPARA2
        tem_falso     : out std_logic;   -- B1: '1' se M_rand e impar
        -- Displays de 7 segmentos
        display0      : out std_logic_vector(6 downto 0);
        display1      : out std_logic_vector(6 downto 0);
        display2      : out std_logic_vector(6 downto 0);
        display3      : out std_logic_vector(6 downto 0);
		  db_latch_a    : out std_logic_vector(2 downto 0);
		  db_latch_b   : out std_logic_vector(2 downto 0);
        db_tempo      : out std_logic_vector(15 downto 0)
    );
end entity fd_jogo_reacao;

architecture arch of fd_jogo_reacao is

    -- =========================================================================
    -- Declaracoes de componentes
    -- =========================================================================
    component contador is
        generic (MODULO : integer := 1000);
        port (
            clock  : in  std_logic;
            clear  : in  std_logic;
            enable : in  std_logic;
            Q      : out std_logic_vector(14 downto 0);
            RCO    : out std_logic
        );
    end component;

    component hex7seg is
        port (
            hex     : in  std_logic_vector(3 downto 0);
            display : out std_logic_vector(6 downto 0)
        );
    end component;

    component lsfr is
        generic (n : integer := 3);
        port (
            clock  : in  std_logic;
            enable : in  std_logic;
            reset  : in  std_logic;
            min    : in  std_logic_vector(n-1 downto 0);
            max    : in  std_logic_vector(n-1 downto 0);
            seed   : in  std_logic_vector(n-1 downto 0);
            d_out  : out std_logic_vector(n-1 downto 0)
        );
    end component;

    -- =========================================================================
    -- Sinais internos: LFSRs e latches
    -- =========================================================================
    -- LFSR_A (seed "001"): gera N_rand -> tempo de espera em PREPARA (A2)
    -- LFSR_B (seed "011"): gera M_rand -> define alarme falso e seu tempo (B1)
    -- Ambos rodam livremente (enable='1'). Os latches congelam os valores
    -- quando o jogo esta em andamento (freeze='1'), garantindo que N_rand e
    -- M_rand nao mudem durante uma rodada.
    signal s_lfsr_a : std_logic_vector(2 downto 0);
    signal s_lfsr_b : std_logic_vector(2 downto 0);

    signal latch_a  : std_logic_vector(2 downto 0);  -- N_rand congelado
    signal latch_b  : std_logic_vector(2 downto 0);  -- M_rand congelado
    signal metade_b : std_logic_vector(2 downto 0);  -- floor(M_rand/2), min=1

    -- freeze='1' durante PREPARA, PREPARA2 ou FALSO_ALARME
    signal freeze   : std_logic;

    -- =========================================================================
    -- Sinais internos: Canal A e Canal B
    -- =========================================================================
    signal enableA    : std_logic;
	 signal s_tick_a   : std_logic;
    signal s_q_secs_a : std_logic_vector(14 downto 0);

    signal s_tick_b   : std_logic;
    signal s_q_secs_b : std_logic_vector(14 downto 0);

    -- =========================================================================
    -- Sinais internos: medicao de tempo de reacao (cadeia BCD)
    -- =========================================================================
    signal rco0, rco1, rco2          : std_logic;
    signal enable0, enable1, enable2 : std_logic;
    signal q_ms0, q_ms1, q_ms2, q_ms3 : std_logic_vector(14 downto 0);
    signal dig0, dig1, dig2, dig3    : std_logic_vector(3 downto 0);
    constant DIGITO_9 : std_logic_vector(3 downto 0) := "1001";

begin

    -- =========================================================================
    -- A2/B1: Dois LFSRs de 3 bits rodando livremente
    --   Intervalo [1, 7] garantido por min="001" e max="111"
    --   LFSR_A (seed "001"): sequencia {1, 3, 6, 4, 1, ...}
    --   LFSR_B (seed "011"): sequencia {3, 6, 4, 1, 3, ...} (fase diferente)
    -- =========================================================================
    LFSR_A : lsfr
        generic map (n => 3)
        port map (
            clock  => clock,
            enable => '1',
            reset  => reset,
            min    => "001",
            max    => "111",
            seed   => "001",
            d_out  => s_lfsr_a
        );

    LFSR_B : lsfr
        generic map (n => 3)
        port map (
            clock  => clock,
            enable => '1',
            reset  => reset,
            min    => "001",
            max    => "111",
            seed   => "011",
            d_out  => s_lfsr_b
        );

    -- =========================================================================
    -- Congelamento dos latches:
    --   Enquanto freeze='0' (estados INICIAL, ESTIMULA, MEDE, FIM, etc.) os
    --   latches seguem os LFSRs continuamente, amostrando valores distintos
    --   a cada rodada. Quando freeze='1' os valores sao preservados.
    -- =========================================================================
    freeze <= contar_espera or contar_falso;

    process(clock, reset)
    begin
        if reset = '1' then
            latch_a <= "001";   -- default: 1 s
            latch_b <= "011";   -- default: 3 (impar -> com alarme falso)
        elsif rising_edge(clock) then
            if freeze = '0' then
                latch_a <= s_lfsr_a;
                latch_b <= s_lfsr_b;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- B1: Calculo de metade_b = floor(M_rand / 2), minimo 1 segundo
    --   Implementado como deslocamento de 1 bit a direita:
    --   '0' & M(2 downto 1) = floor(M/2)
    --   Excecao: M=1 daria 0 -> forçamos minimo de 1 segundo.
    --   Tabela: M=1->1s, M=2->1s, M=3->1s, M=4->2s, M=5->2s, M=6->3s, M=7->3s
    -- =========================================================================
    metade_b <= "001" when latch_b(2 downto 1) = "00"  -- M in {1,2,3} -> 1s
                else '0' & latch_b(2 downto 1);         -- shift right 1

    -- B1: tem_falso = '1' quando M_rand e impar (LSB = '1')
    tem_falso <= latch_b(0) when unsigned(latch_a) > unsigned(metade_b) else
						'0';

    -- =========================================================================
    -- Canal A: contagem de segundos em PREPARA e PREPARA2
    --
    --   SEC_TICK_A gera 1 pulso/s (contador mod 1000 com clock de 1 kHz).
    --   CONT_SECS_A conta os segundos (mod 8 suficiente para [0..7]).
    --
    --   Como clr_espera e assincrono e ativo-alto, o Canal A fica zerado
    --   durante TODO o estado FALSO_ALARME (clr_espera='1'). Ao entrar em
    --   PREPARA2, clr_espera passa para '0' e a contagem recomeca do zero.
    --   Isso garante que passou_metade seja medido desde o inicio de PREPARA2.
    -- =========================================================================
    SEC_TICK_A : contador
        generic map (MODULO => 1000)
        port map (
            clock  => clock,
            clear  => clr_espera,
            enable => enableA, 
            Q      => open,
            RCO    => s_tick_a
        );

    CONT_SECS_A : contador
        generic map (MODULO => 8)
        port map (
            clock  => clock,
            clear  => clr_espera,
            enable => s_tick_a,
            Q      => s_q_secs_a,
            RCO    => open
        );
	
	 -- enable do contador A recebe 1 quando em PREPARA ou PREPARA2 e para de contar em FALSO_ALARME (mas mantem seu valor)
	 enableA 	  <= '1' when (contar_espera = '1') and (contar_falso = '0') else
						  '0';  
    -- A2: passou N_rand segundos em PREPARA (rota sem alarme falso)
    passou_rand  <= '1' when unsigned(s_q_secs_a) >= unsigned(latch_a) else '0';

    -- B1: passou M_rand segundos em PREPARA (hora de ativar alarme falso)
    passou_falso <= '1' when unsigned(s_q_secs_a(2 downto 0)) >= unsigned(latch_b) else '0';

    -- B1: passou M_rand/2 segundos em PREPARA2 (hora do estimulo real pos-alarme)
    -- Usa Canal A pois PREPARA2 tambem usa contar_espera/clr_espera
    passou_metade <= '1' when unsigned(s_q_secs_a(2 downto 0)) >= unsigned(metade_b) else '0';

    -- =========================================================================
    -- Canal B: contagem de 2 segundos fixos em FALSO_ALARME
    --
    --   SEC_TICK_B gera 1 pulso/s.
    --   CONT_SECS_B conta os segundos.
    --   passou_2s sinaliza quando >= 2 segundos se passaram.
    -- =========================================================================
    SEC_TICK_B : contador
        generic map (MODULO => 1000)
        port map (
            clock  => clock,
            clear  => clr_falso,
            enable => contar_falso,
            Q      => open,
            RCO    => s_tick_b
        );

    CONT_SECS_B : contador
        generic map (MODULO => 8)
        port map (
            clock  => clock,
            clear  => clr_falso,
            enable => s_tick_b,
            Q      => s_q_secs_b,
            RCO    => open
        );

    -- B1: 2 segundos fixos no estado FALSO_ALARME
    passou_2s <= '1' when unsigned(s_q_secs_b(2 downto 0)) >= 2 else '0';

    -- =========================================================================
    -- Medicao de tempo de reacao: cadeia de 4 contadores BCD (0-9)
    --   Resolucao: 1 ms (clock de 1 kHz)
    --   Faixa: 0.000 a 9.999 s
    -- =========================================================================
    CONT_MS0 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => clr_tempo,
            enable => contar_tempo,
            Q      => q_ms0,
            RCO    => rco0
        );

    CONT_MS1 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => clr_tempo,
            enable => enable0,
            Q      => q_ms1,
            RCO    => rco1
        );

    CONT_MS2 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => clr_tempo,
            enable => enable1,
            Q      => q_ms2,
            RCO    => rco2
        );

    CONT_MS3 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => clr_tempo,
            enable => enable2,
            Q      => q_ms3,
            RCO    => open
        );

    -- Ripple carry: cada digito so conta quando todos os anteriores transbordaram
    enable0 <= contar_tempo and rco0;
    enable1 <= contar_tempo and rco0 and rco1;
    enable2 <= contar_tempo and rco0 and rco1 and rco2;

    -- Multiplexacao: exibe "9999" em caso de antecipacao, tempo real caso contrario
    dig0 <= DIGITO_9 when sel_erro = '1' else q_ms0(3 downto 0);
    dig1 <= DIGITO_9 when sel_erro = '1' else q_ms1(3 downto 0);
    dig2 <= DIGITO_9 when sel_erro = '1' else q_ms2(3 downto 0);
    dig3 <= DIGITO_9 when sel_erro = '1' else q_ms3(3 downto 0);

    DISP0 : hex7seg port map (hex => dig0, display => display0);
    DISP1 : hex7seg port map (hex => dig1, display => display1);
    DISP2 : hex7seg port map (hex => dig2, display => display2);
    DISP3 : hex7seg port map (hex => dig3, display => display3);

    db_tempo <= dig3 & dig2 & dig1 & dig0;
	 db_latch_a   <= latch_a;
	 db_latch_b   <= latch_b;

end architecture;
