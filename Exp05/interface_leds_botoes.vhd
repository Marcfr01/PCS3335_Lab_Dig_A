entity interface_leds_botoes is
 port (
 clock : in std_logic;
 reset : in std_logic;
 iniciar : in std_logic;
 resposta : in std_logic;
 ligado : out std_logic;
 estimulo : out std_logic;
 pulso : out std_logic;
 erro : out std_logic;
 pronto : out std_logic
 );
end entity interface_leds_botoes;

architecture arch of interface_led_botoes is

	--declaracoes dos componentes utilizados
	
	component UC is
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
		 contar : out std_logic;
		 clr_contador : out std_logic;
		 db_estado : out std_logic_vector(3 downto 0) 
	 );
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
	
	-- declaracao de sinais
	signal passou10, clr_cont, en_cont : std_logic := '0';
	signal db_estado : std_logic_vector;
	
	begin
	
		CONT : contador
			generic map (MODULO => 10000)
			port map (
				clock  => clock,
				clear  => clr_cont,
				enable => en_cont,
				Q      => open,
				RCO    => passou10
      );
		
		Unid_Controle : UC
			port map(
				clock      	  => clock
				reset  	  	  => reset
				iniciar 	  	  => iniciar
				resposta   	  => resposta
				passou10   	  => passou10
				ligado 	  	  => ligado
				estimulo   	  => estimulo
				--pulso : out std_logic;
				erro 		  	  => erro
				pronto     	  => pronto
				contar     	  => en_cont
				clr_contador  => clr_cont
				db_estado  	  => db_estado
			);

end architecture;
