library ieee;
use ieee.std_logic_1164.all;

entity fd_jogo_reacao is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
        clr_espera    : in  std_logic;
        contar_espera : in  std_logic;
        clr_tempo     : in  std_logic;
        contar_tempo  : in  std_logic;
        sel_erro      : in  std_logic;   
        passou5s      : out std_logic;
        display0      : out std_logic_vector(6 downto 0);  
        display1      : out std_logic_vector(6 downto 0);  
        display2      : out std_logic_vector(6 downto 0);  
        display3      : out std_logic_vector(6 downto 0);  
        db_tempo      : out std_logic_vector(15 downto 0)  
    );
end entity fd_jogo_reacao;

architecture arch of fd_jogo_reacao is

    component contador is
        generic (MODULO : integer := 1000);
        port (
            clock  : in  std_logic;
            clear  : in  std_logic;
            enable : in  std_logic;
            Q      : out std_logic_vector(14 downto 0);
            RCO    : out std_logic
        );
    end component;

    component hex7seg is
        port (
            hex     : in  std_logic_vector(3 downto 0);
            display : out std_logic_vector(6 downto 0)
        );
    end component;

    signal rco0, rco1, rco2 : std_logic;

    signal q_ms0, q_ms1, q_ms2, q_ms3 : std_logic_vector(14 downto 0);

    signal dig0, dig1, dig2, dig3 : std_logic_vector(3 downto 0);

    constant DIGITO_9 : std_logic_vector(3 downto 0) := "1001";

begin

    CONT_ESPERA : contador
        generic map (MODULO => 5000)
        port map (
            clock  => clock,
            clear  => clr_espera,
            enable => contar_espera,
            Q      => open,
            RCO    => passou5s
        );

    CONT_MS0 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => clr_tempo,
            enable => contar_tempo,
            Q      => q_ms0,
            RCO    => rco0
        );

    CONT_MS1 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => clr_tempo,
            enable => rco0,
            Q      => q_ms1,
            RCO    => rco1
        );

    CONT_MS2 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => clr_tempo,
            enable => rco1,
            Q      => q_ms2,
            RCO    => rco2
        );

    CONT_MS3 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => clr_tempo,
            enable => rco2,
            Q      => q_ms3,
            RCO    => open
        );

    dig0 <= DIGITO_9                          when sel_erro = '1' else q_ms0(3 downto 0);
    dig1 <= DIGITO_9                          when sel_erro = '1' else q_ms1(3 downto 0);
    dig2 <= DIGITO_9                          when sel_erro = '1' else q_ms2(3 downto 0);
    dig3 <= DIGITO_9                          when sel_erro = '1' else q_ms3(3 downto 0);

    DISP0 : hex7seg port map (hex => dig0, display => display0);
    DISP1 : hex7seg port map (hex => dig1, display => display1);
    DISP2 : hex7seg port map (hex => dig2, display => display2);
    DISP3 : hex7seg port map (hex => dig3, display => display3);
	 
    db_tempo <= dig3 & dig2 & dig1 & dig0;

end architecture;
