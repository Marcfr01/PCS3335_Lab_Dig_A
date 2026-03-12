-- Plano de Testes ----------------------------------------------------------------------
--   #1 Reset inicial: verifica se o semáforo assume estado vermelho com reset ativo	--
--   #2 Vermelho → Verde: verifica transição após 5 s (5000 ciclos)							--
--   #3 Verde → Amarelo: verifica transição após 4 s (4000 ciclos)							--
--   #4 Amarelo → Vermelho: verifica transição após 2 s (2000 ciclos)						--
--   #5 Reset durante Verde: verifica retorno forçado ao estado vermelho antes de 4s   --
----------------------------------------------------------------------------------------- 
 
library ieee;
use ieee.std_logic_1164.all;
 
entity semaforo_tb is
end entity semaforo_tb;
 
architecture testbench of semaforo_tb is
 
    component semaforo is
        port (
            clock    : in  std_logic;
            reset    : in  std_logic;
            vermelho : out std_logic;
            amarelo  : out std_logic;
            verde    : out std_logic
        );
    end component semaforo;
 
    -- Constantes de tempo
    constant T_CLOCK    : time := 1000 ns;  
    constant T_MEIO     : time := 500 ns;   
 
    -- Durações dos estados em número de ciclos (@ 1 kHz)
    constant CICLOS_VERMELHO : integer := 5000; -- 5 s
    constant CICLOS_VERDE    : integer := 4000; -- 4 s
    constant CICLOS_AMARELO  : integer := 2000; -- 2 s
 
    -- Sinais de estímulo e observação
    signal clock    : std_logic := '0';
    signal reset    : std_logic := '0';
    signal vermelho : std_logic;
    signal amarelo  : std_logic;
    signal verde    : std_logic;
 
    -- Aguarda N ciclos de clock
    procedure espera_ciclos(
        signal clk : in std_logic;
        n          : in integer
    ) is
    begin
        for i in 1 to n loop
            wait until rising_edge(clk);
        end loop;
    end procedure espera_ciclos;
 
    -- Imprime resultado de um teste
    procedure checar(
        nome      : in string;
        condicao  : in boolean
    ) is
    begin
        if condicao then
            report nome & " --> PASSOU" severity note;
        else
            report nome & " --> FALHOU" severity error;
        end if;
    end procedure checar;
 
begin
 
    -- Instância do DUT
    DUT: semaforo
        port map (
            clock    => clock,
            reset    => reset,
            vermelho => vermelho,
            amarelo  => amarelo,
            verde    => verde
        );
 

    -- Geração de clock: 1 kHz, duty cycle 50 %
    -- ----------------------------------------------------------
    clock <= not clock after T_MEIO;
 
 
    -- Processo de estímulos
    process
    begin
 
        -- TESTE #1 — Reset inicial
        -- Objetivo: verificar que o semáforo assume e mantém o
        --           estado VERMELHO enquanto reset está ativo.
        -- Resultado esperado: vermelho='1', amarelo='0', verde='0'
        report "========== TESTE #1: Reset inicial ==========" severity note;
 
        reset <= '1';
        espera_ciclos(clock, 10);   -- mantém reset por 10 ciclos
 
        checar("TESTE #1 - vermelho='1' com reset ativo", vermelho = '1');
        checar("TESTE #1 - amarelo='0' com reset ativo",  amarelo  = '0');
        checar("TESTE #1 - verde='0'   com reset ativo",  verde    = '0');
 
        -- TESTE #2 — Transição Vermelho → Verde após 5 s
        -- Objetivo: liberar o reset e aguardar 5000 ciclos;
        --           verificar que a saída muda para verde.
        -- Resultado esperado: verde='1', vermelho='0', amarelo='0'
        report "========== TESTE #2: Vermelho -> Verde (5 s) ==========" severity note;
 
        reset <= '0';
 
        -- Aguarda exatamente 5000 ciclos (tempo do estado vermelho)
        -- Acrescenta 2 ciclos extras para garantir que o RCO foi
        -- capturado e o estado já transitou
        espera_ciclos(clock, CICLOS_VERMELHO + 2);
 
        checar("TESTE #2 - verde='1'    apos 5 s",    verde    = '1');
        checar("TESTE #2 - vermelho='0' apos 5 s",    vermelho = '0');
        checar("TESTE #2 - amarelo='0'  apos 5 s",    amarelo  = '0');
 
        -- TESTE #3 — Transição Verde → Amarelo após 4 s
        -- Objetivo: já estando em verde, aguardar 4000 ciclos e
        --           verificar que a saída muda para amarelo.
        -- Resultado esperado: amarelo='1', vermelho='0', verde='0'
        report "========== TESTE #3: Verde -> Amarelo (4 s) ==========" severity note;
 
        espera_ciclos(clock, CICLOS_VERDE + 2);
 
        checar("TESTE #3 - amarelo='1'  apos 4 s",    amarelo  = '1');
        checar("TESTE #3 - vermelho='0' apos 4 s",    vermelho = '0');
        checar("TESTE #3 - verde='0'    apos 4 s",    verde    = '0');
 
        -- TESTE #4 — Transição Amarelo → Vermelho após 2 s
        -- Objetivo: já estando em amarelo, aguardar 2000 ciclos e
        --           verificar que a saída retorna a vermelho.
        -- Resultado esperado: vermelho='1', amarelo='0', verde='0'
        report "========== TESTE #4: Amarelo -> Vermelho (2 s) ==========" severity note;
 
        espera_ciclos(clock, CICLOS_AMARELO + 2);
 
        checar("TESTE #4 - vermelho='1' apos 2 s",    vermelho = '1');
        checar("TESTE #4 - amarelo='0'  apos 2 s",    amarelo  = '0');
        checar("TESTE #4 - verde='0'    apos 2 s",    verde    = '0');
 
        -- TESTE #5 — Reset forçado durante o estado Verde
        -- Objetivo: após a transição de vermelho para verde (5 s),
        --           acionar reset antes dos 4 s do estado verde
        --           e verificar retorno imediato a vermelho.
        -- Resultado esperado: vermelho='1', amarelo='0', verde='0'
        report "========== TESTE #5: Reset forcado durante Verde ==========" severity note;
 
        -- Aguarda sair do vermelho e entrar em verde (5000 + 2 ciclos)
        espera_ciclos(clock, CICLOS_VERMELHO + 2);
        checar("TESTE #5 - confirmacao: verde='1' antes do reset", verde = '1');
 
        -- Aciona reset no meio do estado verde (após 2000 ciclos, ou seja, 2 s)
        espera_ciclos(clock, 2000);
        reset <= '1';
        espera_ciclos(clock, 3);    -- aguarda alguns ciclos para o reset propagar
 
        checar("TESTE #5 - vermelho='1' apos reset durante verde", vermelho = '1');
        checar("TESTE #5 - amarelo='0'  apos reset durante verde", amarelo  = '0');
        checar("TESTE #5 - verde='0'    apos reset durante verde", verde    = '0');
 
        reset <= '0';
 
        -- Fim da simulação
        report "========== FIM DA SIMULACAO ==========" severity note;
        wait; -- para a simulação
    end process;
 
end architecture;