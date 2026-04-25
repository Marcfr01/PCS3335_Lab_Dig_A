library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fd_jogo_reacao is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        -- controle da fase PREPARA (A2 / B1)
        clr_espera    : in  std_logic;
        contar_espera : in  std_logic;
        -- controle da fase FALSO_ALARME (B1)
        clr_falso     : in  std_logic;
        contar_falso  : in  std_logic;
        -- controle da medicao de tempo de reacao
        clr_tempo     : in  std_logic;
        contar_tempo  : in  std_logic;
        sel_erro      : in  std_logic;
        -- condicoes de tempo para a UC
        passou_rand   : out std_logic;   -- A2
        passou_falso  : out std_logic;   -- B1
        passou_metade : out std_logic;   -- B1
        tem_falso     : out std_logic;   -- B1
        -- displays de 7 segmentos
        display0      : out std_logic_vector(6 downto 0);
        display1      : out std_logic_vector(6 downto 0);
        display2      : out std_logic_vector(6 downto 0);
        display3      : out std_logic_vector(6 downto 0);
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
    signal s_lfsr_a  : std_logic_vector(2 downto 0);  -- saida do LFSR_A (N_rand)
    signal s_lfsr_b  : std_logic_vector(2 downto 0);  -- saida do LFSR_B (M_rand)

    signal latch_a   : std_logic_vector(2 downto 0);  -- N_rand congelado
    signal latch_b   : std_logic_vector(2 downto 0);  -- M_rand congelado
    signal metade_b  : std_logic_vector(2 downto 0);  -- floor(M_rand/2), min=1

    signal freeze    : std_logic;  -- '1' em PREPARA ou FALSO_ALARME

    -- =========================================================================
    -- Sinais internos: Canal A (PREPARA) e Canal B (FALSO_ALARME)
    -- =========================================================================
    signal s_tick_a   : std_logic;                      -- pulso de 1 Hz (canal A)
    signal s_q_secs_a : std_logic_vector(14 downto 0);  -- contador de segundos (canal A)

    signal s_tick_b   : std_logic;                      -- pulso de 1 Hz (canal B)
    signal s_q_secs_b : std_logic_vector(14 downto 0);  -- contador de segundos (canal B)

    -- =========================================================================
    -- Sinais internos: medicao de tempo de reacao
    -- =========================================================================
    signal rco0, rco1, rco2                          : std_logic;
	 signal enable0, enable1, enable2                 : std_logic := '0';
    signal q_ms0, q_ms1, q_ms2, q_ms3                : std_logic_vector(14 downto 0);
    signal dig0, dig1, dig2, dig3                    : std_logic_vector(3 downto 0);
    constant DIGITO_9 : std_logic_vector(3 downto 0) := "1001";

begin

    -- =========================================================================
    -- A2/B1: Dois LFSRs rodando livremente (enable='1' sempre)
    --   LFSR_A: seed "001" -> {1, 3, 6, 4, ...} -> N_rand (tempo de espera A2)
    --   LFSR_B: seed "011" -> {3, 6, 4, 1, ...} -> M_rand (paridade/tempo B1)
    --   min="001", max="111" garante valores no intervalo [1, 7]
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
    --   freeze = '1' durante PREPARA (contar_espera='1') ou
    --                         FALSO_ALARME (contar_falso='1')
    --   Nos demais estados os latches seguem as saidas dos LFSRs
    --   continuamente, garantindo amostragem "aleatoria" a cada rodada.
    -- =========================================================================
    freeze <= contar_espera or contar_falso;

    process(clock, reset)
    begin
        if reset = '1' then
            latch_a <= "001";  -- default: 1 segundo
            latch_b <= "011";  -- default: 3 (impar -> com alarme falso)
        elsif rising_edge(clock) then
            if freeze = '0' then
                latch_a <= s_lfsr_a;
                latch_b <= s_lfsr_b;
            end if;
        end if;
    end process;

    -- =========================================================================
    -- B1: Calculo de metade_b = floor(M_rand / 2), minimo 1 segundo
    --   floor(M/2) = deslocamento direita de 1 bit = '0' & M(2 downto 1)
    --   Minimo de 1 segundo garante que o LED de alarme falso seja visivel
    --   mesmo para M=1 (que daria 0 segundos sem a correcao).
    --   Mapeamento: M=1->"001"(1s), M=3->"001"(1s), M=5->"010"(2s), M=7->"011"(3s)
    -- =========================================================================
    metade_b <= "001" when latch_b(2 downto 1) = "00"  -- M=1: 0->1s (minimo)
                else '0' & latch_b(2 downto 1);         -- M=3->1s, M=5->2s, M=7->3s

    -- B1: tem_falso = LSB do M_rand ('1' se impar)
    tem_falso <= latch_b(0);

    -- =========================================================================
    -- Canal A: contagem de segundos durante PREPARA
    --   SEC_TICK_A: gera 1 pulso por segundo (mod 1000 com clock de 1 kHz)
    --   CONT_SECS_A: conta segundos de 0 a 7
    --   Ambos sao limpos pelo mesmo sinal clr_espera da UC
    -- =========================================================================
    SEC_TICK_A : contador
        generic map (MODULO => 1000)
        port map (
            clock  => clock,
            clear  => clr_espera,
            enable => contar_espera,
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

    -- A2: estimulo verdadeiro sem alarme falso
    passou_rand  <= '1' when unsigned(s_q_secs_a(2 downto 0)) >= unsigned(latch_a) else '0';

    -- B1: ativacao do alarme falso (M_rand segundos em PREPARA)
    passou_falso <= '1' when unsigned(s_q_secs_a(2 downto 0)) >= unsigned(latch_b) else '0';

    -- =========================================================================
    -- Canal B: contagem de segundos durante FALSO_ALARME
    --   SEC_TICK_B: gera 1 pulso por segundo
    --   CONT_SECS_B: conta segundos de 0 a 7
    --   Ambos sao limpos pelo sinal clr_falso da UC
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

    -- B1: estimulo verdadeiro apos alarme falso (metade_b segundos em FALSO_ALARME)
    passou_metade <= '1' when unsigned(s_q_secs_b(2 downto 0)) >= unsigned(metade_b) else '0';

    -- =========================================================================
    -- Medicao de tempo de reacao (inalterado em relacao ao projeto base)
    --   Cadeia de 4 contadores BCD (0-9 cada) -> 4 digitos decimais em ms
    --   Resolucao: 1 ms (clock de 1 kHz)
    --   Faixa: 0,000 a 9,999 segundos
    -- =========================================================================
    CONT_MS0 : contador
        generic map (MODULO => 10)
        port map (clock  => clock, 
		            clear  => clr_tempo, 
						enable => contar_tempo,
                  Q      => q_ms0, 
						RCO    => rco0);

    CONT_MS1 : contador
        generic map (MODULO => 10)
        port map (clock  => clock, 
		            clear  => clr_tempo, 
		            enable => enable0,
                  Q      => q_ms1, 
						RCO    => rco1);

    CONT_MS2 : contador
        generic map (MODULO => 10)
        port map (clock  => clock, 
		            clear  => clr_tempo, 
						enable => enable1,
                  Q      => q_ms2, 
						RCO    => rco2);

    CONT_MS3 : contador
        generic map (MODULO => 10)
        port map (clock  => clock, 
		            clear  => clr_tempo, 
						enable => enable2,
                  Q      => q_ms3, 
						RCO   => open);
	
    -- Enables	
	 enable0 <= contar_tempo and rco0;
	 enable1 <= contar_tempo and rco0 and rco1;
	 enable2 <= contar_tempo and rco0 and rco1 and rco2;

    -- Multiplexacao: exibe "9999" em caso de erro, tempo real caso contrario
    dig0 <= DIGITO_9 when sel_erro = '1' else q_ms0(3 downto 0);
    dig1 <= DIGITO_9 when sel_erro = '1' else q_ms1(3 downto 0);
    dig2 <= DIGITO_9 when sel_erro = '1' else q_ms2(3 downto 0);
    dig3 <= DIGITO_9 when sel_erro = '1' else q_ms3(3 downto 0);

    DISP0 : hex7seg port map (hex => dig0, display => display0);
    DISP1 : hex7seg port map (hex => dig1, display => display1);
    DISP2 : hex7seg port map (hex => dig2, display => display2);
    DISP3 : hex7seg port map (hex => dig3, display => display3);

    db_tempo <= dig3 & dig2 & dig1 & dig0;

end architecture;
