library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity UC is
 port (
 clock : in std_logic;
 reset : in std_logic;
 iniciar : in std_logic;
 resposta : in std_logic;
 passou10 : in std_logic;
 ligado : out std_logic;
 estimulo : out std_logic;
 --pulso : out std_logic;
 erro : out std_logic;
 pronto : out std_logic;
 db_estado : out std_logic_vector(3 downto 0) 
 );
end entity UC;

architecture arch of UC is 
	type estados is (INICIAL, PREPARA, ESTIMULA, ERRO, FIM, ESPERA);
	signal estado_atual, proximo_estado : estados;
	
	begin
		
		process(clock, reset)
		begin
			if reset = '1' then estado_atual <= INICIAL;
			elsif clock'event and clock = '1' then estado_atual <= proximo_estado;
			end if;
		end process;
		
	   --logica de proximo estado
		proximo_estado <= INICIAL when (estado_atual = INICIAL and iniciar  = '0') else 
							   PREPARA  when (estado_atual = INICIAL and iniciar  = '1') else
								ERRO when (estado_atual = PREPARA and resposta = '1') else
							   PREPARA  when (estado_atual = PREPARA and passou10 = '0' and resposta ='0') else
							   ESTIMULA when (estado_atual = PREPARA and passou10 = '1' and resposta ='0') else
							   ESTIMULA when (estado_atual = ESTIMULA and resposta = '0') else
							   FIM when (estado_atual = ESTIMULA and resposta = '1') else
								INICIAL when (estado_atual = FIM and resposta = '0') else
								ESPERA when (estado_atual = FIM and resposta = '1') else
								ESPERA when (estado_atual = ESPERA and resposta = '1') else
								INICIAL when (estado_atual = ESPERA and resposta = '0') else
								ERRO when (estado_atual = ERRO and resposta = '1') else
								INICIAL when (estado_atual = ERRO and resposta = '0') else
							   estado_atual; 
		
		
			-- Saídas 
			with estado_atual select ligado 	  <= '0' when (INICIAL or ERRO), 	'1' when others;
			with estado_atual select estimulo  <= '1' when ESTIMULO, 				'0' when others;
			with estado_atual select erro      <= '1' when ERRO, 	   				'0' when others;
			with estado_atual select pronto    <= '1' when FIM, 	   				'0' when others;
			 
			db_estado <=  "0001" when (estado_atual = INICIAL) else
							  "0010" when (estado_atual = PREPARA) else
							  "0011" when (estado_atual = ESTIMULA)   else
							  "0100" when (estado_atual = FIM)     else
							  "0101" when (estado_atual = ESPERA) else
							  "0110" when (estado_atual = ERRO) else
							  "0000";
							  
end architecture;
