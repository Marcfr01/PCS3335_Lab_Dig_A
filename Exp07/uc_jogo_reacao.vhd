library ieee;
use ieee.std_logic_1164.all;

entity uc_jogo_reacao is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        jogar         : in  std_logic;
        resposta      : in  std_logic;
        -- A2 / B1: sinais de condicao de tempo (vindos do FD)
        tem_falso     : in  std_logic; -- B1
        passou_rand   : in  std_logic; -- A2
        passou_falso  : in  std_logic; -- B1
        passou_metade : in  std_logic; -- B1
        -- saidas de estado
        ligado        : out std_logic;
        estimulo      : out std_logic;
        alarme_falso  : out std_logic; -- B1
        erro          : out std_logic;
        pronto        : out std_logic;
        -- controle do FD: fase PREPARA (A2/B1)
        clr_espera    : out std_logic;
        contar_espera : out std_logic;
        -- controle do FD: fase FALSO_ALARME (B1)
        clr_falso     : out std_logic;
        contar_falso  : out std_logic;
        -- controle do FD: medicao de tempo de reacao
        clr_tempo     : out std_logic;
        contar_tempo  : out std_logic;
        sel_erro      : out std_logic;
		  gbr           : out std_logic_vector(2 downto 0);
        -- debug
        db_estado     : out std_logic_vector(3 downto 0)
    );
end entity uc_jogo_reacao;

architecture arch of uc_jogo_reacao is

    -- Estado FALSO_ALARME adicionado para extensao B1
    type estados is (INICIAL, PREPARA, FALSO_ALARME, ESTIMULA, MEDE, ERROR, FIM, ESPERA, PERDEU);
    signal estado_atual, proximo_estado : estados;

begin

    -- -------------------------------------------------------------------------
    -- Registrador de estado (sincrono, reset assincrono)
    -- -------------------------------------------------------------------------
    process(clock, reset)
    begin
        if reset = '1' then
            estado_atual <= INICIAL;
        elsif rising_edge(clock) then
            estado_atual <= proximo_estado;
        end if;
    end process;

    -- -------------------------------------------------------------------------
    -- Logica de proximo estado
    -- -------------------------------------------------------------------------
    proximo_estado <=
        -- INICIAL: aguarda jogar
        PREPARA      when (estado_atual = INICIAL      and jogar         = '1') else
        INICIAL      when (estado_atual = INICIAL      and jogar         = '0') else

        -- PREPARA: resposta tem prioridade (erro imediato)
        -- A2: sem alarme falso -> aguarda N_rand segundos
        -- B1: com alarme falso -> aguarda M_rand segundos ate alarme
        ERROR        when (estado_atual = PREPARA      and resposta      = '1') else
        FALSO_ALARME when (estado_atual = PREPARA      and tem_falso     = '1'
                                                       and passou_falso  = '1'
                                                       and resposta      = '0') else
        ESTIMULA     when (estado_atual = PREPARA      and tem_falso     = '0'
                                                       and passou_rand   = '1'
                                                       and resposta      = '0') else
        PREPARA      when (estado_atual = PREPARA      and resposta      = '0') else

        -- FALSO_ALARME (B1): LED azul aceso
        --   pressionar botao = FALSO_ALARME (ERROR)
        --   aguardar M_rand/2 segundos -> estimulo verdadeiro
        PERDEU       when (estado_atual = FALSO_ALARME and resposta      = '1') else
        ESTIMULA     when (estado_atual = FALSO_ALARME and passou_metade = '1'
                                                       and resposta      = '0') else
        FALSO_ALARME when (estado_atual = FALSO_ALARME and resposta      = '0') else
		  INICIAL      when (estado_atual = PERDEU       and resposta      = '0') else

        -- ESTIMULA: dura 1 ciclo de clock (transicao imediata para MEDE)
        MEDE         when  estado_atual = ESTIMULA                              else

        -- MEDE: aguarda resposta do jogador
        FIM          when (estado_atual = MEDE         and resposta      = '1') else
        MEDE         when (estado_atual = MEDE         and resposta      = '0') else

        -- FIM: aguarda botao ser solto para voltar ao inicio
        ESPERA       when (estado_atual = FIM          and resposta      = '1') else
        INICIAL      when (estado_atual = FIM          and resposta      = '0') else

        -- ESPERA: botao ainda pressionado apos FIM
        ESPERA       when (estado_atual = ESPERA       and resposta      = '1') else
        INICIAL      when (estado_atual = ESPERA       and resposta      = '0') else

        -- ERROR: aguarda botao ser solto
        ESPERA       when (estado_atual = ERROR        and resposta      = '1') else
        INICIAL      when (estado_atual = ERROR        and resposta      = '0') else

        estado_atual;  -- default: permanece no estado atual

    -- -------------------------------------------------------------------------
    -- Logica de saida (Moore)
    -- -------------------------------------------------------------------------
    ligado       <= '0' when (estado_atual = INICIAL or estado_atual = ERROR) else '1';
    estimulo     <= '1' when (estado_atual = ESTIMULA or estado_atual = MEDE) else '0';
    alarme_falso <= '1' when  estado_atual = FALSO_ALARME                     else '0';
    erro         <= '1' when  estado_atual = ERROR                            else '0';
    pronto       <= '1' when (estado_atual = FIM or estado_atual = ESPERA)    else '0';
    sel_erro     <= '1' when  estado_atual = ERROR                            else '0';

    -- Controle do contador de espera (fase PREPARA - A2 e B1)
    contar_espera <= '1' when  estado_atual = PREPARA      else '0';
    clr_espera    <= '0' when  estado_atual = PREPARA      else '1';

    -- Controle do contador de alarme falso (fase FALSO_ALARME - B1)
    contar_falso  <= '1' when  estado_atual = FALSO_ALARME else '0';
    clr_falso     <= '0' when  estado_atual = FALSO_ALARME else '1';

    -- Controle do contador de tempo de reacao (fase MEDE)
    contar_tempo  <= '1' when  estado_atual = MEDE         else '0';
    clr_tempo     <= '0' when (estado_atual = MEDE     or estado_atual = FIM
                           or  estado_atual = ESPERA   or estado_atual = ESTIMULA) else '1';

    -- Codificacao de debug (visivel nos LEDs vermelhos da DE0-CV)
    db_estado <= "0001" when estado_atual = INICIAL      else  -- 1
                 "0010" when estado_atual = PREPARA      else  -- 2
                 "0011" when estado_atual = ESTIMULA     else  -- 3
                 "0100" when estado_atual = MEDE         else  -- 4
                 "0101" when estado_atual = FIM          else  -- 5
                 "0110" when estado_atual = ESPERA       else  -- 6
                 "0111" when estado_atual = ERROR        else  -- 7
                 "1000" when estado_atual = FALSO_ALARME else  -- 8 (novo)
					  "1001" when estado_atual = PERDEU       else
                 "0000";
					  
	 gbr <= "101" when estado_atual = ERROR else 
			  "100" when estado_atual = PREPARA else 
			  "001" when (estado_atual = ESTIMULA or estado_atual = MEDE) else 
			  "010" when estado_atual = FALSO_ALARME else
			  "000";

end architecture;
