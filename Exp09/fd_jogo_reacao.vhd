-------------------------------------------------------------------------------
-- Arquivo   : fd_jogo_reacao.vhd
-- Descricao : Fluxo de Dados do Jogo do Tempo de Reacao
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fd_jogo_reacao is
    port (
        clock         : in  std_logic; --NOVOS SINAIS:
        reset         : in  std_logic; -- ENTRADA: teclado em logic vector
													-- SAIDA: buzz, resposta, passou05, teclado em binario (acertou ou nao, entrada pra UC)
		  
		  -- clock de 50MHz para o buzzer
        clock50       : in  std_logic;
		  ledar         : in  std_logic;
		  
		  -- Barramento PS/2 (teclado mecanico)
        ps2_clk       : in  std_logic;
        ps2_data      : in  std_logic;
		  
		  -- Controle da musica 1
		  tocar1        : in  std_logic;
		  incr1         : in  std_logic;
		  resetP1       : in  std_logic;
    
        -- Controle da musica 2
        tocar2        : in  std_logic;
		  incr2         : in  std_logic;
		  resetP2       : in  std_logic;

		  --Controle de tempo
		  enableCont    : in  std_logic;
		  resetCont     : in  std_logic;
		  
		  -- Somar pontos
		  somarPts      : in std_logic;
		  
		  -- Zerar pontos
		  zerarPts      : in std_logic;
		  
		  -- sinal de indicacao de fim da nota
		  notou         : out std_logic;
		  passou05      : out std_logic;
		  
		  -- sinais de indicacao de fim da musica
		  fim1          : out std_logic;
		  fim2          : out std_logic;
		  
		  -- Resposta do jogador via teclado PS/2
        -- bit 0=S  bit 1=D  bit 2=F  bit 3=G  bit 4=H  bit 5=J  bit 6=K
        resposta      : out std_logic_vector(6 downto 0);
		  
		  -- Nota sendo tocada no momento (one-hot, bits 16:10 do dado da ROM)
        -- Usada pela UC para verificar acerto sem acessar a ROM diretamente
        nota_atual    : out std_logic_vector(6 downto 0);
		  
        -- Displays de 7 segmentos
        display0      : out std_logic_vector(6 downto 0);
        display1      : out std_logic_vector(6 downto 0);
        display2      : out std_logic_vector(6 downto 0);
        display3      : out std_logic_vector(6 downto 0);
		  
		  -- led rgb
		  rgb           : out std_logic_vector(2 downto 0);
		  
		  -- buzzer
		  buzz          : out std_logic;
		  
		  -- pontuacao do jogador 
		  pontos       : out std_logic_vector(9 downto 0); -- pode-se depois mudar o maximo de pontos (atual = 1023)

		  -- sinal de depuracao
        db_tempo      : out std_logic_vector(15 downto 0)
    );
end entity fd_jogo_reacao;

architecture arch of fd_jogo_reacao is

    -- =========================================================================
    -- Declaracoes de componentes
    -- =========================================================================
	 -- Teclado mecânico
	 component ps2_top is
        port (
            clk       : in  std_logic;
            rst       : in  std_logic;
            ps2_clk   : in  std_logic;
            ps2_data  : in  std_logic;
            key_code  : out std_logic_vector(7 downto 0);
            key_make  : out std_logic;
            key_break : out std_logic;
            key_valid : out std_logic;
            extended  : out std_logic
        );
    end component;
 
    component ps2_key_mapper is
        port (
            clk       : in  std_logic;
            rst       : in  std_logic;
            key_code  : in  std_logic_vector(7 downto 0);
            key_make  : in  std_logic;
            key_break : in  std_logic;
            key_valid : in  std_logic;
            resposta  : out std_logic_vector(6 downto 0)
        );
    end component;
	 
	 -- Buzzer
	 component ControleBuzzerNotas is
		 port (
			  clk       : in  STD_LOGIC;                         
			  rst       : in  STD_LOGIC;                         
			  en        : in  STD_LOGIC;                         
			  nota_in   : in  STD_LOGIC_VECTOR(2 downto 0);      
			  buzz_out  : out STD_LOGIC                          
		 );
	end component;
	 
	 -- Memoria
    component memoriaMusicas is
		generic (
			addressSize : natural := 8;
			dataSize    : natural := 8;
			datFileName : string := "memInstr_conteudo.dat"
		);
		port (
			addr : in  std_logic_vector (addressSize - 1 downto 0);
			data : out std_logic_vector (dataSize - 1 downto 0)
		);
	end component;
	 

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
	 
	 
	 function conversao_rgb(cor : std_logic_vector(6 downto 0))
        return std_logic_vector is
    begin
        case cor is
            when "1000000" => return "100"; -- Vermelho
            when "0100000" => return "010"; -- Verde
            when "0010000" => return "001"; -- Azul
            when "0001000" => return "110"; -- Amarelo
            when "0000100" => return "101"; -- Roxo
            when "0000010" => return "011"; -- Ciano
            when "0000001" => return "111"; -- Branco
            when others    => return "000"; -- Apagado / invalido
        end case;
    end function;

	 function conversao_nota(data : std_logic_vector(6 downto 0))
        return std_logic_vector is
    begin
        case data is
            when "1000000" => return "000"; -- A4
            when "0100000" => return "001"; -- B4
            when "0010000" => return "010"; -- C5
            when "0001000" => return "011"; -- D5
            when "0000100" => return "100"; -- E5
            when "0000010" => return "101"; -- F5
            when "0000001" => return "110"; -- G5
            when others    => return "111"; -- 0
        end case;
    end function;
    -- =========================================================================
    -- Sinais internos: Controle do contador auxiliar
    -- =========================================================================
	 
	 signal s_key_code  : std_logic_vector(7 downto 0);
    signal s_key_make  : std_logic;
    signal s_key_break : std_logic;
    signal s_key_valid : std_logic;
    signal s_extended  : std_logic;  -- ignorado (teclas mapeadas nao sao estendidas)
	 
    --signal enableCont    : std_logic;
	 --signal resetCont     : std_logic;
	 signal tempoCont     : std_logic_vector(14 downto 0);
	 
	 -- =========================================================================
    -- Sinais internos: Endereco e conteudo da ROM
    -- =========================================================================
	 constant tamanho          : natural := 3; -- tamanho generico dos endereços da ROM das músicas
	 signal pointer1, pointer2 : std_logic_vector(14 downto 0);
	 signal data1, data2       : std_logic_vector(17 downto 0);
	 signal tempo              : std_logic_vector(10 downto 0);
	 
    -- =========================================================================
    -- Sinais internos: medicao de tempo de reacao (cadeia BCD)
    -- =========================================================================
    signal rco0, rco1, rco2          : std_logic;
    signal enable0, enable1, enable2 : std_logic;
    signal q_ms0, q_ms1, q_ms2, q_ms3 : std_logic_vector(14 downto 0);
    signal dig0, dig1, dig2, dig3    : std_logic_vector(3 downto 0);
	 
	 -- =========================================================================
    -- Sinais internos: controle de frequencia do buzzer
    -- =========================================================================
	 signal frequency                 : std_logic_vector(7 downto 0);
	 
	 	 type matrix_8x17 is array (0 to 7) of std_logic_vector(0 to 17);
	 constant MATRIZ_EXEMPLO1 : matrix_8x17 := (
    0 => "100000010000001011",
    1 => "010000010000001011",
    2 => "001000010000001011",
    3 => "000100010000001011",
    4 => "000010010000001011",
    5 => "000001010000001011",
    6 => "000000110000001011",
    7 => (others => '0')
);
	constant MATRIZ_EXEMPLO2 : matrix_8x17  := (
	 0 => "000000110000001011",
	 1 => "000001010000001011",
	 2 => "000010010000001011",
	 3 => "000100010000001011",
	 4 => "001000010000001011",
	 5 => "010000010000001011",
	 6 => "100000010000001011",
	 7 => "000000000000000000"
);

	signal nota                      : std_logic_vector(2 downto 0);

	-- Pontuação das notas 
	-- mudar a pontuacao caso necessario 
	constant acertou_nota_perfeito : unsigned(9 downto 0)	:= "0000110010"; -- 50 pontos
	--constant acertou_nota_paiamente : std_logic_vector(9 downto 0); -- caso colocarmos o perfeito e normal
	signal pontos_t : unsigned(9 downto 0) := "0000000000";
	
begin


	U_PS2 : ps2_top
        port map (
            clk       => clock,
            rst       => reset,
            ps2_clk   => ps2_clk,
            ps2_data  => ps2_data,
            key_code  => s_key_code,
            key_make  => s_key_make,
            key_break => s_key_break,
            key_valid => s_key_valid,
            extended  => s_extended
        );
		  
	U_MAPPER : ps2_key_mapper
        port map (
            clk       => clock,
            rst       => reset,
            key_code  => s_key_code,
            key_make  => s_key_make,
            key_break => s_key_break,
            key_valid => s_key_valid,
            resposta  => resposta
        );

    -- =========================================================================
    -- Cont : contador de suporte usado na contagem de tempo das musicas
    --   Modulo 5000 (5s em 1kHz)
    -- =========================================================================
    Cont : contador
        generic map (MODULO => 5000)
        port map (
            clock  => clock,
            clear  => resetCont,
            enable => enableCont,
				Q      =>  tempoCont,
				RCO    =>  open
        );
		  
	notou <= '1' when (unsigned(tempoCont) >= unsigned(tempo)) else '0';
	passou05 <= '1' when (unsigned(tempoCont) >= 500) else '0';
	--resetCont  <= '0' when ((tocar1 = '1' or tocar2 = '1') and unsigned(tempoCont) < unsigned(tempo)) else '1';
	--enableCont <= '1' when (tocar1 = '1' or tocar2 = '1') else '0';
	 
	 -- =========================================================================
    -- Cont : Pointers 1 e 2
    --   Modulo 5000 (5s em 1kHz)
    -- =========================================================================
	 P1 : contador
        generic map (MODULO => 2**tamanho)
        port map (
            clock  => clock,
            clear  => resetP1,
            enable => incr1,
				Q      =>  pointer1,
				RCO    =>  fim1
        );
		  
	 P2 : contador
        generic map (MODULO => 2**tamanho)
        port map (
            clock  => clock,
            clear  => resetP2,
            enable => incr2,
				Q      =>  pointer2,
				RCO    =>  fim2
        );
	 
	 
	 -- =========================================================================
    -- Memoria ROM para musicas 1 e 2
    --   Carregadas por arquivos .dat
	 --   Conteudo : 7 notas + 10 bits para indicar tempo (intervalo [0; 1023])
    -- =========================================================================
	 
	  data1 <= MATRIZ_EXEMPLO1(to_integer(unsigned(pointer1))) when tocar1 = '1' else
			 (others => '0');
	  data2 <= MATRIZ_EXEMPLO2(to_integer(unsigned(pointer2))) when tocar2 = '1' else
			 (others => '0');
			 
	  nota_atual <= data1(17 downto 11) when tocar1 = '1' else
                  data2(17 downto 11) when tocar2 = '1' else
                  (others => '0');
 
   --M1 : memoriaMusicas
   --    generic map (
	--		  addressSize => tamanho,
	--		  dataSize    => 17,  
	--		  datFileName => "musica1.dat"
	--	  )
   --    port map (
   --        addr => pointer1(tamanho - 1 downto 0),
	--			data => data1
   --    );
--
   --M2 : memoriaMusicas
   --    generic map (
	--		  addressSize => tamanho,
	--		  dataSize    => 17,  
	--		  datFileName => "musica2.dat"
	--	  )
   --    port map (
   --        addr => pointer2(tamanho - 1 downto 0),
	--			data => data2
   --    );
	
	rgb <= conversao_rgb(data1(17 downto 11)) when (tocar1 = '1' and ledar = '1') else
			 conversao_rgb(data2(17 downto 11)) when (tocar2 = '1' and ledar = '1') else
			 "000";
			 
	tempo <= data1(10 downto 0) when tocar1 = '1' else
				data2(10 downto 0) when tocar2 = '1' else
				(others => '0');
				
	 pontos_t <= pontos_t + acertou_nota_perfeito when somarPts = '1' else 
					 "0000000000"                     when zerarPts = '1' else
					 pontos_t ;
	
		 -- =========================================================================
    -- Gerador de PWM: controle do buzzer
    --   Ligado quando led estiver ligado
	 --   Controle de frequencia dado por nota (data(17 downto 10))
    -- =========================================================================
	buzzer : ControleBuzzerNotas
	 port map(
		clk      => clock50,
		rst      => reset,
		en       => ledar,
		nota_in  => nota,
		buzz_out => buzz
	 );
	
	 nota <= conversao_nota(data1(17 downto 11)) when tocar1 = '1' else
			   conversao_nota(data2(17 downto 11)) when tocar2 = '1' else
			   (others => '0');
    -- =========================================================================
    -- Medicao de tempo para transicao de nota: cadeia de 4 contadores BCD (0-9)
    --   Resolucao: 1 ms (clock de 1 kHz)
    --   Faixa: 0.000 a 9.999 s
    -- =========================================================================
    CONT_MS0 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => resetCont,
            enable => enableCont,
            Q      => q_ms0,
            RCO    => rco0
        );

    CONT_MS1 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => resetCont,
            enable => enable0,
            Q      => q_ms1,
            RCO    => rco1
        );

    CONT_MS2 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => resetCont,
            enable => enable1,
            Q      => q_ms2,
            RCO    => rco2
        );

    CONT_MS3 : contador
        generic map (MODULO => 10)
        port map (
            clock  => clock,
            clear  => resetCont,
            enable => enable2,
            Q      => q_ms3,
            RCO    => open
        );

    -- Ripple carry: cada digito so conta quando todos os anteriores transbordaram
    enable0 <= enableCont and rco0;
    enable1 <= enableCont and rco0 and rco1;
    enable2 <= enableCont and rco0 and rco1 and rco2;

    dig0 <= q_ms0(3 downto 0);
    dig1 <= q_ms1(3 downto 0);
    dig2 <= q_ms2(3 downto 0);
    dig3 <= q_ms3(3 downto 0);

    DISP0 : hex7seg port map (hex => dig0, display => display0);
    DISP1 : hex7seg port map (hex => dig1, display => display1);
    DISP2 : hex7seg port map (hex => dig2, display => display2);
    DISP3 : hex7seg port map (hex => dig3, display => display3);

    db_tempo <= dig3 & dig2 & dig1 & dig0;
	 
	 pontos <= std_logic_vector(pontos_t);


end architecture;
