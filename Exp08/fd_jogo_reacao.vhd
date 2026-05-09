-------------------------------------------------------------------------------
-- Arquivo   : fd_jogo_reacao.vhd
-- Descricao : Fluxo de Dados do Jogo do Tempo de Reacao
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity fd_jogo_reacao is
    port (
        clock         : in  std_logic;
        reset         : in  std_logic;
		  
        -- Controle da musica 1
		  tocar1        : in  std_logic;
        --clr_espera1   : in  std_logic;
        --contar_espera1: in  std_logic;
		  
        -- Controle da musica 2
        tocar2        : in  std_logic;
		  --clr_espera2   : in  std_logic;
        --contar_espera2: in  std_logic;
		  
        -- Controle da medicao de tempo de reacao
        --clr_tempo     : in  std_logic;
        --contar_tempo  : in  std_logic;
        --sel_erro      : in  std_logic;
		  
        -- Condicoes de tempo para a UC
        --passou_rand   : out std_logic;   -- A2: N_rand s em PREPARA (sem alarme)
        --passou_falso  : out std_logic;   -- B1: M_rand s em PREPARA (com alarme)
        --passou_2s     : out std_logic;   -- B1: 2 s fixos em FALSO_ALARME
        --passou_metade : out std_logic;   -- B1: M_rand/2 s em PREPARA2
        --tem_falso     : out std_logic;   -- B1: '1' se M_rand e impar
		  
		  -- sinais de indicacao de fim da musica
		  fim1          : out std_logic;
		  fim2          : out std_logic;
		  
        -- Displays de 7 segmentos
        display0      : out std_logic_vector(6 downto 0);
        display1      : out std_logic_vector(6 downto 0);
        display2      : out std_logic_vector(6 downto 0);
        display3      : out std_logic_vector(6 downto 0);
		  
		  --led rgb
		  rgb           : out std_logic_vector(2 downto 0);
		  --db_latch_a    : out std_logic_vector(2 downto 0);
		  --db_latch_b   : out std_logic_vector(2 downto 0);
		  
        db_tempo      : out std_logic_vector(15 downto 0)
    );
end entity fd_jogo_reacao;

architecture arch of fd_jogo_reacao is

    -- =========================================================================
    -- Declaracoes de componentes
    -- =========================================================================
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

	 
    -- =========================================================================
    -- Sinais internos: Controle do contador auxiliar
    -- =========================================================================
    signal enableCont    : std_logic;
	 signal resetCont     : std_logic;
	 signal tempoCont     : std_logic_vector(14 downto 0);
	 
	 -- =========================================================================
    -- Sinais internos: Endereco e conteudo da ROM
    -- =========================================================================
	 constant tamanho          : natural := 3; -- tamanho generico dos endereços da ROM das músicas
	 signal pointer1, pointer2 : std_logic_vector(tamanho - 1 downto 0);
	 signal data1, data2       : std_logic_vector(16 downto 0);
	 signal tempo              : std_logic_vector(9 downto 0);
	 
    -- =========================================================================
    -- Sinais internos: medicao de tempo de reacao (cadeia BCD)
    -- =========================================================================
    signal rco0, rco1, rco2          : std_logic;
    signal enable0, enable1, enable2 : std_logic;
    signal q_ms0, q_ms1, q_ms2, q_ms3 : std_logic_vector(14 downto 0);
    signal dig0, dig1, dig2, dig3    : std_logic_vector(3 downto 0);

begin

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
		  
	resetCont  <= '0' when ((tocar1 = '1' or tocar2 = '1') and unsigned(tempoCont) < unsigned(tempo)) else '1';
	enableCont <= '1' when (tocar1 = '1' or tocar2 = '1') else '0';
	 
	 -- =========================================================================
    -- Memoria ROM para musicas 1 e 2
    --   Carregadas por arquivos .dat
	 --   Conteudo : 7 notas + 10 bits para indicar tempo (intervalo [0; 1023])
    -- =========================================================================
    M1 : memoriaMusicas
        generic map (
			  addressSize => tamanho,
			  dataSize    => 17,  
			  datFileName => "musica1.dat"
		  )
        port map (
            addr => pointer1,
				data => data1
        );

    M2 : memoriaMusicas
        generic map (
			  addressSize => tamanho,
			  dataSize    => 17,  
			  datFileName => "musica2.dat"
		  )
        port map (
            addr => pointer2,
				data => data2
        );
	
	rgb <= conversao_rgb(data1(16 downto 10)) when tocar1 = '1' else
			 conversao_rgb(data2(16 downto 10)) when tocar2 = '1' else
			 "000";
			 
	tempo <= data1(9 downto 0) when tocar1 = '1' else
				data2(9 downto 0) when tocar2 = '1' else
				(others => '0');
	
	process(clock, reset)
		begin
			 if reset = '1' then
				  pointer1 <= (others => '0');
			 elsif rising_edge(clock) then
				  if (tocar1 = '1' and unsigned(tempoCont) < unsigned(tempo)) then 
						pointer1 <= std_logic_vector(unsigned(pointer1) + 1);
				  elsif (tocar1 = '0') then
						pointer1 <= (others => '0'); -- zera se não estiver tocando
				  end if;
			 end if;
	end process;
	
	process(clock, reset)
		begin
			 if reset = '1' then
				  pointer2 <= (others => '0');
			 elsif rising_edge(clock) then
				  if (tocar2 = '1' and unsigned(tempoCont) < unsigned(tempo)) then 
						pointer2 <= std_logic_vector(unsigned(pointer2) + 1);
				  elsif (tocar2 = '0') then
						pointer2 <= (others => '0'); -- zera se não estiver tocando
				  end if;
			 end if;
	end process;
	
	fim1 <= '1' when unsigned(pointer1) = (tamanho) else '0';
	fim2 <= '1' when unsigned(pointer2) = (tamanho) else '0';
	
	--pointer1 <= pointer1 									when (tocar1 = '1' and unsigned(tempoCont) < unsigned(tempo)) else
	--				std_logic_vector(unsigned(pointer1) + 1)  when (tocar1 = '1' and unsigned(tempoCont) = unsigned(tempo)) else
	--				(others => '0');
	
	--pointer2 <= pointer2 									when (tocar2 = '1' and unsigned(tempoCont) < unsigned(tempo)) else
	--				std_logic_vector(unsigned(pointer2) + 1)  when (tocar2 = '1' and unsigned(tempoCont) = unsigned(tempo)) else
	--				(others => '0');
	
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


end architecture;
