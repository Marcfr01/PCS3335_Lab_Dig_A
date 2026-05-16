library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ControleBuzzerNotas is
    port (
        clk       : in  STD_LOGIC;                         -- Clock de entrada (50 MHz)
        rst       : in  STD_LOGIC;                         -- Reset assíncrono
        en        : in  STD_LOGIC;                         -- '1' liga o som, '0' desliga
        nota_in   : in  STD_LOGIC_VECTOR(2 downto 0);      -- Seleciona a nota (0 a 12)
        buzz_out  : out STD_LOGIC                          -- Saída para o buzzer passivo
    );
end ControleBuzzerNotas;

architecture Comportamento of ControleBuzzerNotas is

    type tabela_notas is array (0 to 12) of integer;
    
    -- Referencia Frequencia da notas: https://mixbutton.com/music-tools/frequency-and-pitch/music-note-to-frequency-chart
    -- Fórmula: 25.000.000 / Frequência_da_Nota
    constant LUT_NOTAS : tabela_notas := (
        0  => 101239,  -- (B3)  ->  246,94 Hz
        1  => 270270,  -- (F#2) ->  92,50 Hz	
        2  => 67529 ,  -- (F#4) ->  369,99 Hz
        3  => 255102,  -- (G2)  ->  98 Hz          NOTAS SWEDEN
        4  => 90194 ,  -- (C#4) ->  277,18 Hz
        5  => 227272,  -- (A2)  ->  110 Hz
        6  => 75842 ,  -- (E4)  ->  329,63 Hz
		  7  => 0	  ,  -- Nada
    );

    signal counter    : integer range 0 to 30000 := 0;
    signal max_count  : integer range 0 to 30000 := 246,94; -- Padrão: B3
    signal toggle_sig : STD_LOGIC := '0';
    
begin

    -- Processo Combinacional para carregar o limite da nota
    process(nota_in)
        variable indice : integer;
    begin
        indice := to_integer(unsigned(nota_in));
        
        if (indice >= 0 and indice <= 12) then
            max_count <= LUT_NOTAS(indice);
        else
            max_count <= LUT_NOTAS(0); -- Padrão caso o valor seja inválido (13 a 15)
        end if;
    end process;

    -- Processo Sequencial para gerar pwm
    process(clk, rst)
    begin
        if rst = '1' then
            counter <= 0;
            toggle_sig <= '0';
        elsif rising_edge(clk) then
            if en = '1' then
                if counter >= (max_count - 1) then
                    counter <= 0;
                    toggle_sig <= not toggle_sig;
                else
                    counter <= counter + 1;
                end if;
            else
                counter <= 0;
                toggle_sig <= '0';
            end if;
        end if;
    end process;

    buzz_out <= toggle_sig;

end Comportamento;
