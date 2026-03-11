library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity semaforo_uc is
	port (
		clock 			: in std_logic;
		reset 			: in std_logic;
		rco_vermelho 	: out std_logic; -- Final do tempo do estado vermelho (5 sec)
		rco_amarelo 	: out std_logic; -- Final do tempo do estado amarelo (2 sec)
		rco_verde 		: out std_logic; -- Final do tempo do estado verde (4 sec)
		en_vermelho 	: out std_logic; -- Enable do Contador de tempo do estado vermelho
		en_amarelo 		: out std_logic; -- Enable do Contador de tempo do estado amarelo
		en_verde 		: out std_logic; -- Enable do Contador de tempo do estado verde
		clr_vermelho 	: out std_logic; -- Clear do contador de tempo do estado vermelho
		clr_amarelo 	: out std_logic; -- Clear do contador de tempo do estado amarelo
		clr_verde 		: out std_logic -- Clear do contador de tempo do estado verde
	);
end entity semaforo_uc;

architecture arch of semaforo_uc is
		type estado_t is (VERMELHO, AMARELO, VERDE);
		signal estado_atual, proximo_estado : estado_t;
begin

	-- Unidade de Controle 
	process(clock, reset, enable)
		if reset = '1' then estado_atual <= VERMELHO;
		elsif clock'event and clock = '1' then estado_atual <= proximo_estado;
		end if;
	end process;
	
	-- Fluxo de Dados (lógica de próximo estado)
	proximo_estado <= VERDE    when (estado_atual = VERMELHO and rco_vermelho = '1') else
							AMARELO  when (estado_atual = VERDE    and rco_verde    = '1') else
							VERMELHO when (estado_atual = AMARELO  and rco_amarelo  = '1') else
							estado_atual; 
	
	-- Fluxo de Dados (Saídas)
	with estado_atual select en_vermelho 	<= '1' when VERMELHO, 	'0' when others;
	with estado_atual select en_verde 		<= '1' when VERDE, 		'0' when others;
	with estado_atual select en_amarelo 	<= '1' when AMARELO, 	'0' when others;	
	with estado_atual select clr_vermelho 	<= '0' when VERMELHO, 	'1' when others;
	with estado_atual select clr_verde 		<= '0' when VERDE, 		'1' when others;
	with estado_atual select clr_amarelo 	<= '0' when AMARELO, 	'1' when others;
	
end architecture;