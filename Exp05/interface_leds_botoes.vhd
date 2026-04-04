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
		 db_estado : out std_logic_vector(3 downto 0) 
	 );
	end component;

	begin

end architecture;
