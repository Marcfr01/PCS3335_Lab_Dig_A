library ieee;
use ieee.std_logic_1164.all;

entity uc_jogo_reacao is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        jogar         : in  std_logic;
        resposta      : in  std_logic;
        passou5s      : in  std_logic;   
        ligado        : out std_logic;
        estimulo      : out std_logic;
        erro          : out std_logic;
        pronto        : out std_logic;
        clr_espera    : out std_logic;   
        contar_espera : out std_logic;   
        clr_tempo     : out std_logic;   
        contar_tempo  : out std_logic;   
        sel_erro      : out std_logic;   
        db_estado     : out std_logic_vector(3 downto 0)
    );
end entity uc_jogo_reacao;

architecture arch of uc_jogo_reacao is

    type estados is (INICIAL, PREPARA, ESTIMULA, MEDE, ERROR, FIM, ESPERA);
    signal estado_atual, proximo_estado : estados;

begin

    process(clock, reset)
    begin
        if reset = '1' then estado_atual <= INICIAL;
        elsif rising_edge(clock) then estado_atual <= proximo_estado;
        end if;
    end process;

    proximo_estado <= PREPARA  when (estado_atual = INICIAL  and jogar    = '1') else
                      INICIAL  when (estado_atual = INICIAL  and jogar    = '0') else
                      ERROR    when (estado_atual = PREPARA  and resposta = '1') else
                      ESTIMULA when (estado_atual = PREPARA  and passou5s = '1' and resposta = '0') else
                      PREPARA  when (estado_atual = PREPARA  and passou5s = '0' and resposta = '0') else
                      MEDE     when  estado_atual = ESTIMULA                    else
                      FIM      when (estado_atual = MEDE     and resposta = '1') else
                      MEDE     when (estado_atual = MEDE     and resposta = '0') else
                      ESPERA   when (estado_atual = FIM      and resposta = '1') else
                      INICIAL  when (estado_atual = FIM      and resposta = '0') else
                      ESPERA   when (estado_atual = ESPERA   and resposta = '1') else
                      INICIAL  when (estado_atual = ESPERA   and resposta = '0') else
                      ESPERA   when (estado_atual = ERROR    and resposta = '1') else
                      INICIAL  when (estado_atual = ERROR    and resposta = '0') else
                      estado_atual;


    ligado   <= '0' when (estado_atual = INICIAL or estado_atual = ERROR) else '1';
    estimulo <= '1' when (estado_atual = ESTIMULA or estado_atual = MEDE) else '0';
    erro     <= '1' when  estado_atual = ERROR   else '0';
    pronto   <= '1' when (estado_atual = FIM or estado_atual = ESPERA) else '0';
    sel_erro <= '1' when  estado_atual = ERROR   else '0';

    contar_espera <= '1' when  estado_atual = PREPARA  else '0';
    clr_espera    <= '0' when  estado_atual = PREPARA  else '1';

    contar_tempo  <= '1' when  estado_atual = MEDE     else '0';
    clr_tempo     <= '0' when (estado_atual = MEDE or estado_atual = FIM
                               or estado_atual = ESPERA or estado_atual = ESTIMULA) else '1';

    db_estado <= "0001" when estado_atual = INICIAL  else
                 "0010" when estado_atual = PREPARA  else
                 "0011" when estado_atual = ESTIMULA else
                 "0100" when estado_atual = MEDE     else
                 "0101" when estado_atual = FIM      else
                 "0110" when estado_atual = ESPERA   else
                 "0111" when estado_atual = ERROR    else
                 "0000";

end architecture;
