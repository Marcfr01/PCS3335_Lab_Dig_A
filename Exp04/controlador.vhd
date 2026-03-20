library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controlador is 
	port( 
		clock 	 : in  std_logic;
		reset 	 : in  std_logic;
		liga 		 : in  std_logic;
		sinal 	 : in  std_logic;
		zeraCont  : out std_logic;
		contaCont : out std_logic;
		pronto 	 : out std_logic;
		db_estado : out std_logic_vector(3 downto 0) -- sinal de depuracao
	);
end entity;

architecture arch of controlador is 
	type estados is (INICIAL, LIGADO, PREPARA, CONTA, FIM, ESPERA);
	signal estado_atual, proximo_estado : estados;
	
begin
	
	process(clock, reset)
	begin
		if reset = '1' then estado_atual <= INICIAL;
		elsif clock'event and clock = '1' then estado_atual <= proximo_estado;
		end if;
	end process;
	
	-- Lógica de próximo estado
	proximo_estado <= INICIAL when (estado_atual = INICIAL and liga  = '0') else 
					  INICIAL when (estado_atual = ESPERA  and liga  = '0') else 
					  LIGADO  when (estado_atual = INICIAL and liga  = '1') else
					  LIGADO  when (estado_atual = LIGADO  and sinal = '0') else 
					  PREPARA when (estado_atual = LIGADO  and sinal = '1') else 
					  PREPARA when (estado_atual = ESPERA  and (sinal = '1' and liga = '1')) else 
					  CONTA   when (estado_atual = PREPARA) else 
					  CONTA   when (estado_atual = CONTA   and sinal = '1') else 
					  FIM     when (estado_atual = CONTA   and sinal = '0') else 
					  ESPERA  when (estado_atual = FIM     and sinal = '1') else 
					  ESPERA  when (estado_atual = ESPERA  and (sinal = '0' and liga = '1')) else 
					  estado_atual;
						
	-- Saídas 
	with estado_atual select zeraCont   <= '1' when PREPARA, '0' when others;
	with estado_atual select contaCont 	<= '1' when CONTA, 	 '0' when others;
	with estado_atual select pronto     <= '1' when FIM, 	 '0' when others;
	
	db_estado <= "0001" when (estado_atual = INICIAL) else
                 "0010" when (estado_atual = LIGADO)  else
                 "0011" when (estado_atual = PREPARA) else
                 "0100" when (estado_atual = CONTA)   else
                 "0101" when (estado_atual = FIM)     else
                 "0110" when (estado_atual = ESPERA)  else
                 "0000";
	
end architecture;
