library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

-- entidade do testbench
entity semaforo_uc_tb is
end entity;

architecture tb of semaforo_uc_tb is

  -- Componente a ser testado (Device Under Test -- DUT)
  component semaforo_uc is
		port (
			clock 			: in  std_logic;
			reset 			: in  std_logic;
			rco_vermelho 	: in  std_logic; -- Final do tempo do estado vermelho (5 sec)
			rco_amarelo 	: in  std_logic; -- Final do tempo do estado amarelo (2 sec)
			rco_verde 		: in  std_logic; -- Final do tempo do estado verde (4 sec)
			en_vermelho 	: out std_logic; -- Enable do Contador de tempo do estado vermelho
			en_amarelo 		: out std_logic; -- Enable do Contador de tempo do estado amarelo
			en_verde 		: out std_logic; -- Enable do Contador de tempo do estado verde
			clr_vermelho 	: out std_logic; -- Clear do contador de tempo do estado vermelho
			clr_amarelo 	: out std_logic; -- Clear do contador de tempo do estado amarelo
			clr_verde 		: out std_logic  -- Clear do contador de tempo do estado verde
		);
  end component;
  
  ---- Declaracao de sinais de entrada para conectar o componente
  signal clock_in  : std_logic 			:= '0';
  signal reset_in  : std_logic 			:= '0';
  signal rco_vermelho_in : std_logic 	:= '0';
  signal rco_amarelo_in : std_logic 	:= '0';
  signal rco_verde_in : std_logic 		:= '0';

  ---- Declaracao dos sinais de saida
  signal en_vermelho_out      : std_logic := '0';
  signal clr_vermelho_out     : std_logic := '0';
  signal en_amarelo_out       : std_logic := '0';
  signal clr_amarelo_out    	: std_logic := '0';
  signal en_verde_out      	: std_logic := '0';
  signal clr_verde_out    		: std_logic := '0';
  

  -- Configurações do clock
  signal keep_simulating : std_logic := '0'; -- delimita o tempo de geração do clock
  constant clockPeriod   : time := 1 us;      -- frequencia 1kHz
  
  -- Casos de teste
  signal caso            : integer := 0;

begin
  clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
  
  ---- DUT para Caso de Teste 1
  dut: semaforo_uc
		port map
      (
         clock   			=>  clock_in,
			reset          => reset_in,
			rco_vermelho 	=> rco_vermelho_in,
			rco_amarelo 	=> rco_amarelo_in,
			rco_verde 		=> rco_verde_in,
			en_vermelho 	=> en_vermelho_out,
			en_amarelo 		=> en_amarelo_out,
			en_verde 		=> en_verde_out,
			clr_vermelho 	=> clr_vermelho_out,
			clr_amarelo 	=> clr_amarelo_out, 
			clr_verde      => clr_verde_out
      );
		
  ---- Gera sinais de estimulo para a simulacao
  stimulus: process is
  begin
	
    -- inicio da simulacao
    assert false report "inicio da simulacao" severity note;
    keep_simulating <= '1';  -- inicia geracao do sinal de clock

    -- Teste #1: reset, estado atual: VERMELHO
    caso     <= 1;
    reset_in <= '1';
    wait for 2*clockPeriod;
    reset_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste 2: rco_Vermelho='0', estado continua em VERMELHO
    caso     <= 2;
	 rco_amarelo_in <= '1';
	 rco_verde_in <= '1';
    wait for clockPeriod;
	 rco_amarelo_in <= '0';
	 rco_verde_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste #3: rco_vermelho='1', estado muda para VERDE
    caso      <= 3;
	 rco_vermelho_in <= '1';
    wait for clockPeriod;
	 rco_vermelho_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste 4: rco_verde = '0', estado continua em VERDE
    caso     <= 4;
	 rco_vermelho_in <= '1';
	 rco_amarelo_in <= '1';
    wait for clockPeriod;
	 rco_vermelho_in <= '0';
	 rco_amarelo_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste 5: rco_verde = '1', estado muda para AMARELO
    caso     <= 5;
	 rco_verde_in <= '1';
    wait for clockPeriod;
	 rco_verde_in <= '0';
    wait until falling_edge(clock_in);
	 
	 -- Teste 6: rco_amarelo = '0', estado continua em AMARELO
    caso     <= 6;
	 rco_vermelho_in <= '1';
	 rco_verde_in <= '1';
    wait for clockPeriod;
	 rco_vermelho_in <= '0';
	 rco_verde_in <= '0';
    wait until falling_edge(clock_in);
	 
	 -- Teste 7: rco_amarelo = '1', estado muda para VERMELHO
    caso     <= 7;
	 rco_amarelo_in <= '1';
    wait for clockPeriod;
	 rco_amarelo_in <= '0';
    wait until falling_edge(clock_in);
	 
	 -- Teste 8: estado atual em VERDE e reset muda para VERMELHO
    caso     <= 8;
	 rco_vermelho_in <= '1'; -- muda do VERMELHO para VERDE
    wait for clockPeriod;
	 rco_vermelho_in <= '0';
	 reset_in <= '1';
    wait for clockPeriod;
	 reset_in <= '0';
    wait until falling_edge(clock_in);
	 
	 -- Teste 9: estado atual em AMARELO e reset muda para VERMELHO
    caso     <= 9;
	 rco_vermelho_in <= '1'; -- muda do VERMELHO para VERDE
    wait for clockPeriod;
	 rco_vermelho_in <= '0';
	 rco_verde_in <= '1';       -- muda do VERDE para AMARELO
	 wait for clockPeriod;
	 rco_verde_in <= '0';
	 reset_in <= '1';
	 wait for clockPeriod;
	 reset_in <= '0';
	 wait until falling_edge(clock_in);
	 
    -- tempo até final do testbench (5 periodos de clock)
    caso     <= 99;
    wait for 5*clockPeriod;  
 
    ---- final do testbench
    assert false report "fim da simulacao" severity note;
    keep_simulating <= '0';
    
    wait; -- fim da simulação: processo aguarda indefinidamente
  end process;
 

end architecture;
