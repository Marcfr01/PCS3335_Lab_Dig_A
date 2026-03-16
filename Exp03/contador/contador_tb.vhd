library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use std.textio.all;

-- entidade do testbench
entity contador_tb is
end entity;

architecture tb of contador_tb is

  -- Componente a ser testado (Device Under Test -- DUT)
  component contador is
		generic (
			MODULO 	: integer := 1000 -- modulo do contador
		);
      port (
          clock   : in  std_logic;
          clear   : in  std_logic;
          enable  : in  std_logic;
          Q       : out std_logic_vector(14 downto 0);
          RCO     : out std_logic
      );
  end component;
  
  ---- Declaracao de sinais de entrada para conectar o componente
  signal clock_in  : std_logic := '0';
  signal clear_in  : std_logic := '0';
  signal enable_in : std_logic := '0';

  ---- Declaracao dos sinais de saida
  signal q1_out      : std_logic_vector(14 downto 0) := (others => '0');
  signal rco1_out    : std_logic := '0';
  signal q2_out      : std_logic_vector(14 downto 0) := (others => '0');
  signal rco2_out    : std_logic := '0';
  signal q3_out      : std_logic_vector(14 downto 0) := (others => '0');
  signal rco3_out    : std_logic := '0';
  
  ---- Declaracao dos sinais de contagem de fim
  --queria adicionar esses sinais que contam quantas vezes cada contador
  --terminou de contar mas nn sei onde ficaria isso
  --signal fim1 : integer := 0;
  --signal fim2 : integer := 0;
  --signal fim3 : integer := 0;

  -- Configurações do clock
  signal keep_simulating : std_logic := '0'; -- delimita o tempo de geração do clock
  constant clockPeriod   : time := 1 us;      -- frequencia 1kHz
  
  -- Casos de teste
  signal caso            : integer := 0;

begin
  clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
  
  --fim1 <= fim1+1 when rco1_out='1' else 
	--		 fim1;
			
  --fim2 <= fim2+1 when rco2_out='1' else 
	--		 fim2;
			
  --fim3 <= fim3+1 when rco3_out='1' else 
	--		 fim3;
			 
  ---- DUT para Caso de Teste 1
  dut1: contador
		generic map (MODULO => 5000)
      port map
      (
          clock   =>  clock_in, 
          clear   =>  clear_in,
          enable  =>  enable_in,
          Q       =>  q1_out,
          RCO     =>  rco1_out
      );
		
	dut2: contador
		generic map (MODULO => 4000)
      port map
      (
          clock   =>  clock_in, 
          clear   =>  clear_in,
          enable  =>  enable_in,
          Q       =>  q2_out,
          RCO     =>  rco2_out
      );
		
   dut3: contador
		generic map (MODULO => 2000)
      port map
      (
          clock   =>  clock_in, 
          clear   =>  clear_in,
          enable  =>  enable_in,
          Q       =>  q3_out,
          RCO     =>  rco3_out
      );
 
  ---- Gera sinais de estimulo para a simulacao
  stimulus: process is
  begin
	
    -- inicio da simulacao
    assert false report "inicio da simulacao" severity note;
    keep_simulating <= '1';  -- inicia geracao do sinal de clock

    -- Teste #1: gera pulso de clear assincrono (2 periodos de clock)
    -- (sinais de controle mudam nas bordas de descida do clock)
    -- resultado esperado: q1,q2,q3=0 e rco1,rco2,rco3=0
    caso     <= 1;
    clear_in <= '1';
    wait for 2*clockPeriod;
    clear_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste 2: espera por 2 periodos de clock sem habilitacao de contagem
    -- resultado esperado: q1,q2,q3=0 e rco1,rco2,rco3=0
    caso     <= 2;
    wait for 2*clockPeriod;
    wait until falling_edge(clock_in);

    -- Teste #3: habilita contagem por 10.000 periodos de clock
    -- resultados esperados: a contagem de DUT1 será feita 2x, a contagem de DUT2 será feita 2,5x e a contagem de DUT3 será feita 5x
    -- RCO permanece em 0, exceto quando qn=MODULOn-1
    caso      <= 3;
    enable_in <= '1';
    wait for 10000*clockPeriod;
    enable_in <= '0';
    wait until falling_edge(clock_in);

    -- Teste 4: clear assincrono  
    -- resultado esperado: q1,q2,q3=0 e rco1,rco2,rco3=0   
    caso     <= 4;
    clear_in <= '1';
    wait for clockPeriod;
    clear_in <= '0';
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
