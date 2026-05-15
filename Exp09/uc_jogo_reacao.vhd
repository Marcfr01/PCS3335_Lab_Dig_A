library ieee;
use ieee.std_logic_1164.all;

entity uc_jogo_reacao is
    port (
        clock         : in  std_logic; --NOVOS SINAIS:
        reset         : in  std_logic; -- ENTRADA: passouu05, resposta
        jogar         : in  std_logic; -- SAIDA: somarPts, ledar	  
		  botao_next    : in  std_logic;
		  botao_sel     : in  std_logic;        
		  retry			 : in  std_logic;
		  fim1          : in  std_logic;
		  fim2          : in  std_logic;
		  notou         : in  std_logic;
		  
		  passou05      : in  std_logic; -- passou 500 ms 
		  resposta      : in  std_logic; -- resposta ja analisada pelo fd
		  
		  incr1         : out std_logic;   
		  incr2         : out std_logic;
		  resetP1       : out std_logic;
		  resetP2       : out std_logic;
        ligado        : out std_logic;
        perdeu        : out std_logic;
		  tocar1        : out std_logic;
		  tocar2        : out std_logic;
		  pronto        : out std_logic;
		  enableCont    : out std_logic;
		  resetCont     : out std_logic;
		  
		  somarPts      : out std_logic; -- '1' somente em ACERTOU1 ou ACERTOU2
		  ledar         : out std_logic; -- acender led, aceso ate a pessoa responder
													-- da pra usar no controle do buzzer tbm

		  num_musica    : out std_logic_vector(3 downto 0);
        db_estado     : out std_logic_vector(3 downto 0)
    );
end entity uc_jogo_reacao;

architecture arch of uc_jogo_reacao is

    type estados is (INICIAL, MUSICA1, MUSICA2, JOGA1, RESPOSTA1, ACERTOU1, ERROU1, ESPERA1, PROXIMA1, JOGA2, RESPOSTA2, ACERTOU2, ERROU2, ESPERA2, PROXIMA2, FIM);  -- falta estado FIM (usar pointers do FD)
    signal estado_atual, proximo_estado : estados;
	 signal s_botao_next : std_logic := '0';
	 signal botao_next_reg : std_logic := '0';
	 
	 begin

    process(clock, reset)
		begin
			if reset = '1' then estado_atual <= INICIAL;
			elsif rising_edge(clock) then estado_atual <= proximo_estado;
			end if;
	 end process;
	 
	process(clock)
		begin
			 if rising_edge(clock) then
					botao_next_reg <= botao_next;
			 end if;
	end process;
	
	s_botao_next <= '1' when (botao_next = '1' and botao_next_reg = '0') else '0';

    proximo_estado <= INICIAL  when (estado_atual = INICIAL and jogar     = '0') else
							 MUSICA1  when (estado_atual = INICIAL and jogar     = '1') else
							 
							 JOGA1    when (estado_atual = MUSICA1 and botao_sel = '1') else
							 MUSICA1  when (estado_atual = MUSICA1 and botao_sel = '0' and s_botao_next = '0') else
							 MUSICA2  when (estado_atual = MUSICA1 and botao_sel = '0' and s_botao_next = '1') else
							 
							 JOGA2    when (estado_atual = MUSICA2 and botao_sel = '1') else
							 MUSICA2  when (estado_atual = MUSICA2 and botao_sel = '0' and s_botao_next = '0') else
							 MUSICA1  when (estado_atual = MUSICA2 and botao_sel = '0' and s_botao_next = '1') else
							 
							 -- NOVAS TRANSICOES
							 
							 RESPOSTA1 when (estado_atual = JOGA1   and fim1      = '0') else
							 FIM       when (estado_atual = JOGA1   and fim1      = '1') else
							 
							 RESPOSTA1 when (estado_atual = RESPOSTA1 and passou05 = '0' and resposta = '0') else
							 ERROU1    when (estado_atual = RESPOSTA1 and passou05 = '1' and resposta = '0') else
							 ACERTOU1  when (estado_atual = RESPOSTA1 and resposta = '1') else
							 
							 ESPERA1   when (estado_atual = ACERTOU1 or estado_atual = ERROU1) else
							 
							 ESPERA1   when (estado_atual = ESPERA1 and notou = '0') else
							 PROXIMA1  when (estado_atual = ESPERA1 and notou = '1') else
							 
							 JOGA1    when (estado_atual = PROXIMA1) else    
							 
							 RESPOSTA2 when (estado_atual = JOGA2   and fim2      = '0') else
							 FIM       when (estado_atual = JOGA1   and fim2      = '1') else
							 
							 RESPOSTA2 when (estado_atual = RESPOSTA2 and passou05 = '0' and resposta = '0') else
							 ERROU2    when (estado_atual = RESPOSTA2 and passou05 = '1' and resposta = '0') else
							 ACERTOU2  when (estado_atual = RESPOSTA2 and resposta = '1') else
							 
							 ESPERA2   when (estado_atual = ACERTOU2 or estado_atual = ERROU2) else
							 
							 ESPERA2   when (estado_atual = ESPERA2 and notou = '0') else
							 PROXIMA2  when (estado_atual = ESPERA2 and notou = '1') else
							 
							 JOGA2    when (estado_atual = PROXIMA2) else 
							 
							 -- FIM NOVAS TRANSICOES
							 
							 FIM      when (estado_atual = FIM     and retry    = '0') else
							 MUSICA1  when (estado_atual = FIM     and retry    = '1') else
                      
							 estado_atual;


    ligado   <= '0' when (estado_atual = INICIAL) else '1';
	 tocar1   <= '1' when (estado_atual = JOGA1 or estado_atual = RESPOSTA1 or estado_atual = ACERTOU1 or estado_atual = ERROU1 or estado_atual = ESPERA1 or estado_atual = PROXIMA1)   else '0';
	 tocar2   <= '1' when (estado_atual = JOGA2 or estado_atual = RESPOSTA2 or estado_atual = ACERTOU2 or estado_atual = ERROU2 or estado_atual = ESPERA2 or estado_atual = PROXIMA2)   else '0';
	 pronto   <= '1' when (estado_atual = FIM) 	  else '0';
	 
	 incr1    <= '1' when (estado_atual = PROXIMA1) else '0';
	 incr2    <= '1' when (estado_atual = PROXIMA2) else '0';
	 
	 resetP1  <= '0' when (estado_atual = JOGA1 or estado_atual = PROXIMA1) else '1';
	 resetP2  <= '0' when (estado_atual = JOGA2 or estado_atual = PROXIMA2) else '1';
	 
	 enableCont <= '1' when (estado_atual = RESPOSTA1 or estado_atual = ACERTOU1 or estado_atual = ERROU1 or estado_atual = ESPERA1) else
						'1' when (estado_atual = RESPOSTA2 or estado_atual = ACERTOU2 or estado_atual = ERROU2 or estado_atual = ESPERA2) else
						'0';
						
	 resetCont  <= '0' when (estado_atual = RESPOSTA1 or estado_atual = ACERTOU1 or estado_atual = ERROU1 or estado_atual = ESPERA1) else
						'0' when (estado_atual = RESPOSTA2 or estado_atual = ACERTOU2 or estado_atual = ERROU2 or estado_atual = ESPERA2) else
						'1';
	
-- fica um estado extra	aceso em relacao ao enable (JOGA1 e JOGA2), ou seja primeiro o led acende e 1 ciclo de clock dps ele comeca a contar
-- alem disso, ele fica apagado enquanto esta no estado de ESPERA (1 e 2)
	 ledar      <= '1' when (estado_atual = JOGA1 or estado_atual = RESPOSTA1 or estado_atual = ACERTOU1 or estado_atual = ERROU1) else
						'1' when (estado_atual = JOGA2 or estado_atual = RESPOSTA2 or estado_atual = ACERTOU2 or estado_atual = ERROU2) else
						'0';
						
	 somarPts   <= '1' when (estado_atual = ACERTOU1 or estado_atual = ACERTOU2) else '0';
	 

	 
	 num_musica <= "0001" when estado_atual = MUSICA1 else
					   "0010" when estado_atual = MUSICA2 else 
						"0000";

    db_estado <= "0001" when estado_atual = INICIAL  else
                 "0010" when estado_atual = MUSICA1  else
                 "0011" when estado_atual = MUSICA2  else
                 "0100" when (estado_atual = JOGA1 or estado_atual = PROXIMA1)    else
                 "0101" when (estado_atual = JOGA2 or estado_atual = PROXIMA2)    else
                 "0110" when estado_atual = FIM      else
					  --"0111" when estado_atual = PERDE   else
                 "0000";

end architecture;
