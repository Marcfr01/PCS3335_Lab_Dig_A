library ieee;
use ieee.std_logic_1164.all;

entity uc_jogo_reacao is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        jogar         : in  std_logic;
		  
		  botao_next    : in  std_logic;
		  botao_sel     : in  std_logic;
		  errou 			 : in  std_logic; -- aqui usa errou como entrada apenas para testar o funcionamento das musica
													-- no projeto final errou sera dado pela nao resposta ou resposta errada do jogador
        retry			 : in  std_logic;
		  fim1          : in  std_logic;
		  fim2          : in  std_logic;
		  notou         : in  std_logic;
		  --resposta      : in  std_logic;
        --passou5s      : in  std_logic; 
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
		  --estimulo      : out std_logic;
        --erro          : out std_logic;
        --pronto        : out std_logic;
        --clr_espera    : out std_logic;   
        --contar_espera : out std_logic;   
        --clr_tempo     : out std_logic;   
        --contar_tempo  : out std_logic;   
        --sel_erro      : out std_logic;   
		  --loss			 : out std_logic;
		  num_musica    : out std_logic_vector(3 downto 0);
        db_estado     : out std_logic_vector(3 downto 0)
    );
end entity uc_jogo_reacao;

architecture arch of uc_jogo_reacao is

    type estados is (INICIAL, MUSICA1, MUSICA2, JOGA1, PROXIMA1, JOGA2, PROXIMA2, FIM, PERDE);  -- falta estado FIM (usar pointers do FD)
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

							 JOGA1    when (estado_atual = JOGA1   and fim1      = '0'  and notou       = '0' and errou ='0') else
							 PROXIMA1 when (estado_atual = JOGA1   and fim1      = '0'  and notou       = '1' and errou ='0') else
							 FIM      when (estado_atual = JOGA1   and fim1      = '1' and errou ='0') else
							 
							 JOGA1    when (estado_atual = PROXIMA1) else    
							 
							 JOGA2    when (estado_atual = JOGA2   and fim2      = '0'  and notou       = '0' and errou ='0') else
							 PROXIMA2 when (estado_atual = JOGA2   and fim2      = '0'  and notou       = '1' and errou ='0') else
							 FIM      when (estado_atual = JOGA2   and fim2      = '1' and errou ='0') else
							 
							 JOGA2    when (estado_atual = PROXIMA2) else
							 
							 PERDE   when (estado_atual = JOGA1   and errou    = '1') else
							 
							 PERDE   when (estado_atual = JOGA2   and errou    = '1') else
							 
							 FIM      when (estado_atual = FIM     and retry    = '0') else
							 MUSICA1  when (estado_atual = FIM     and retry    = '1') else
							 
							 PERDE   when (estado_atual = PERDE  and retry     = '0') else
							 MUSICA1  when (estado_atual = PERDE  and retry     = '1') else
                      
							 estado_atual;


    ligado   <= '0' when (estado_atual = INICIAL) else '1';
    perdeu   <= '1' when (estado_atual = PERDE)  else '0';
	 tocar1   <= '1' when (estado_atual = JOGA1)   else '0';
	 tocar2   <= '1' when (estado_atual = JOGA2)   else '0';
	 pronto   <= '1' when (estado_atual = FIM) 	  else '0';
	 
	 incr1    <= '1' when (estado_atual = PROXIMA1) else '0';
	 incr2    <= '1' when (estado_atual = PROXIMA2) else '0';
	 
	 resetP1  <= '0' when (estado_atual = JOGA1 or estado_atual = PROXIMA1) else '1';
	 resetP2  <= '0' when (estado_atual = JOGA2 or estado_atual = PROXIMA2) else '1';
	 
	 enableCont <= '1' when (estado_atual = JOGA1 or estado_atual = JOGA2) else '0';
	 resetCont  <= '0' when (estado_atual = JOGA1 or estado_atual = JOGA2) else '1';
	 
	 --resetP1    <= '0' when (estado_atual = JOGA1 or estado_atu
	 
    
	 
    --estimulo <= '1' when (estado_atual = ESTIMULA or estado_atual = MEDE) else '0';
    --sel_erro <= '1' when  estado_atual = ERROR   else '0';

    --contar_espera <= '1' when  estado_atual = PREPARA  else '0';
    --clr_espera    <= '0' when  estado_atual = PREPARA  else '1';

    --contar_tempo  <= '1' when  estado_atual = MEDE     else '0';
    --clr_tempo     <= '0' when (estado_atual = MEDE or estado_atual = FIM
    --                           or estado_atual = ESPERA or estado_atual = ESTIMULA) else '1';
	 
	 num_musica <= "0001" when estado_atual = MUSICA1 else
					   "0010" when estado_atual = MUSICA2 else 
						"0000";

    db_estado <= "0001" when estado_atual = INICIAL  else
                 "0010" when estado_atual = MUSICA1  else
                 "0011" when estado_atual = MUSICA2  else
                 "0100" when estado_atual = JOGA1    else
                 "0101" when estado_atual = JOGA2    else
                 "0110" when estado_atual = FIM      else
					  "0111" when estado_atual = PERDE   else
                 "0000";

end architecture;
