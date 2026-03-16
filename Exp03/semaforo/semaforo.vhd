library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity semaforo is
	port (
		clock 	 : in std_logic;
		reset 	 : in std_logic;
		vermelho : out std_logic;
		amarelo  : out std_logic;
		verde 	 : out std_logic
	
		-- Desafio: implementar em um LED RGB
		cor_vermelha : out std_logic;
		cor_verde    : out std_logic
		cor_azul     : out std_logic;
	);
end entity semaforo;

architecture arch of semaforo is

	component semaforo_uc is
		port(
			clock        : in  std_logic;
			reset        : in  std_logic;
			rco_vermelho : in  std_logic;
			rco_amarelo  : in  std_logic;
			rco_verde    : in  std_logic;
			en_vermelho  : out std_logic;
			en_amarelo   : out std_logic;
			en_verde     : out std_logic;
			clr_vermelho : out std_logic;
			clr_amarelo  : out std_logic;
			clr_verde    : out std_logic);
    end component;

	component contador is
		generic(	
			MODULO : integer := 1000
      );
      port(
         clock  : in  std_logic;
         clear  : in  std_logic;
         enable : in  std_logic;
         Q      : out std_logic_vector(14 downto 0);
         RCO    : out std_logic);
	end component;


   signal en_verm,  en_amar,  en_verd   : std_logic;
   signal clr_verm, clr_amar, clr_verd  : std_logic;
	signal rco_verm, rco_amar, rco_verd  : std_logic;
	
begin

   UC : semaforo_uc 
		port map(
			clock        => clock,
			reset        => reset,
			rco_vermelho => rco_verm,
			rco_amarelo  => rco_amar,
			rco_verde    => rco_verd,
			en_vermelho  => en_verm,
			en_amarelo   => en_amar,
			en_verde     => en_verd,
			clr_vermelho => clr_verm,
			clr_amarelo  => clr_amar,
			clr_verde    => clr_verd);
			
	CONT_VERMELHO : contador
      generic map (MODULO => 5000)
      port map (
         clock  => clock,
         clear  => clr_verm,
         enable => en_verm,
         Q      => open,
         RCO    => rco_verm
      );

   CONT_VERDE : contador
      generic map (MODULO => 4000)
      port map (
         clock  => clock,
         clear  => clr_verd,
         enable => en_verd,
         Q      => open,
         RCO    => rco_verd
      );

   CONT_AMARELO : contador
      generic map (MODULO => 2000)
      port map (
			clock  => clock,
			clear  => clr_amar,
			enable => en_amar,
			Q      => open,
			RCO    => rco_amar
      );
		
	vermelho <= en_verm;
	amarelo  <= en_amar;
	verde    <= en_verd;

	cor_veremlha <= '1' when ((en_verm or en_amarela) = '1'), else '0';
	cor_verde    <= '1' when ((en_verd or en_amarela) = '1'), else '0';
	cor_azul     <= '0' -- Não utilizada para as cores do semáforo
end architecture;
