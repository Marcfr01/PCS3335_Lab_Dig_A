library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cont10_4digitos_7seg is
port (
	clock, clear, enable   : in std_logic;
	Q0, Q1, Q2, Q3         : out std_logic_vector(6 downto 0);
	RCO 	           : out std_logic);
end entity cont10_4digitos_7seg;

architecture arch of cont10_4digitos_7seg is
	
	component cont10_4digitos is
		port (
			clock, clear, enable   : in std_logic;
			Q0, Q1, Q2, Q3         : out std_logic_vector(3 downto 0);
			RCO 	           : out std_logic);
	end component;
	
	component hex7seg is
		port (  
				hex      : in  std_logic_vector(3 downto 0);
				display  : out std_logic_vector(6 downto 0)
		);
	end component;
	
	--sinais intermediarios de contagem
	signal q0_hex, q1_hex, q2_hex, q3_hex : std_logic_vector(3 downto 0) := (others => '0');
	
	begin
		
		cont : cont10_4digitos
			port map(
				clock   	=>  clock, 
				clear   	=>  clear,
				enable  	=>  enable,
				Q0       =>  q0_hex,
				Q1       =>  q1_hex,
				Q2       =>  q2_hex,
				Q3       =>  q3_hex,
				RCO     	=>  RCO
			);
			
		conversor0 : hex7seg 
			port map(
				hex 		=> q0_hex,
				display  => Q0
			);
		
		conversor1 : hex7seg 
			port map(
				hex 		=> q1_hex,
				display 	=> Q1
			);
		
		conversor2 : hex7seg 
			port map(
				hex 		=> q2_hex,
				display 	=> Q2
			);
			
		conversor3 : hex7seg 
			port map(
				hex 		=> q3_hex,
				display 	=> Q3
			);
		
end architecture;