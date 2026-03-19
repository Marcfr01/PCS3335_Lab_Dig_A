library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity medidor_largura is
	 port (
		clock : in std_logic;
		reset : in std_logic;
		liga : in std_logic;
		sinal : in std_logic;
		display0 : out std_logic_vector(6 downto 0);
		display1 : out std_logic_vector(6 downto 0);
		display2 : out std_logic_vector(6 downto 0);
		display3 : out std_logic_vector(6 downto 0);
		db_estado : out std_logic_vector(6 downto 0);
		pronto : out std_logic;
		fim : out std_logic;
		db_clock : out std_logic;
		db_sinal : out std_logic;
		db_zeraCont : out std_logic;
		db_contaCont : out std_logic
	 );
end entity medidor_largura;

architecture arch of medidor_largura is
	
	--declaracoes dos componentes utilizados
	component controlador is
	 port (
		clock 	 : in std_logic;
		reset 	 : in std_logic;
		liga 		 : in std_logic;
		sinal 	 : in std_logic;
		zeraCont  : out std_logic;
		contaCont : out std_logic;
		pronto    : out std_logic;
		db_estado : out std_logic_vector(3 downto 0) 
	 );
	end component;
	
	component cont10_4digitos_7seg is
	 port (
		clock 		: in std_logic;
		clear 		: in std_logic;
		enable   	: in std_logic;
		Q0				: out std_logic_vector(6 downto 0);
		Q1				: out std_logic_vector(6 downto 0);
		Q2				: out std_logic_vector(6 downto 0);
		Q3          : out std_logic_vector(6 downto 0);
		RCO 	      : out std_logic);
	 end component;
	 
	 component hex7seg is
		port (  
				hex      : in  std_logic_vector(3 downto 0);
				display  : out std_logic_vector(6 downto 0)
		);
	  end component;
	 
	 -- sinais de controle para o contador
	 signal zerar, contar : std_logic := '0';
	 
	 --si
	 signal db_estado_hex : std_logic_vector(3 downto 0) := (others => '0');
	 --sinais de saida do contador, em 4 bits
	 --signal q0, q1, q2, q3 : std_logic_vector(3 downto 0) := (others => '0');
	 
	begin
		
		contr : controlador 
			port map(
				clock 	 => clock,
				reset 	 => reset,
				liga 		 => liga,
				sinal 	 => sinal,
				zeraCont  => zerar,
				contaCont => contar,
				pronto    => pronto,
				db_estado => db_estado_hex
				);
				
		contador : cont10_4digitos_7seg
			port map(
				clock   	=>  clock, 
				clear   	=>  zerar,
				enable  	=>  contar,
				Q0       =>  display0,
				Q1       =>  display1,
				Q2       =>  display2,
				Q3       =>  display3,
				RCO     	=>  fim
				);
		
		conversor : hex7seg
			port map(
				hex 		=> db_estado_hex,
				display  => db_estado
			);
		
		--atribuicoes dos sinais de depuracao
		db_clock 	 <= clock;
		db_sinal 	 <= sinal;
		db_zeraCont  <= zerar;
		db_contaCont <= contar;
	
end architecture;
				
		
	
	
	
	
	
	
	
	
	