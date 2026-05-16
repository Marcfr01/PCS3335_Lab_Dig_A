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
    
    -- Referencia Frequencia da notas: https://iazzetta.eca.usp.br/tutor/acustica/introducao/tabela1.html
    -- Fórmula: 25.000.000 / Frequência_da_Nota
    constant LUT_NOTAS : tabela_notas := (
        0  => 28409,  -- Lá 4  (A4)  ->  880,00 Hz
        1  => 26815,  -- Lá# 4 (A#4) -> ~932,33 Hz
        2  => 25310,  -- Si 4  (B4)  -> ~987,77 Hz
        3  => 23889,  -- Dó 5  (C5)  -> ~1046,50 Hz
        4  => 22548,  -- Dó# 5 (C#5) -> ~1108,73 Hz
        5  => 21283,  -- Ré 5  (D5)  -> ~1174,66 Hz
        6  => 20088,  -- Ré# 5 (D#5) -> ~1244,51 Hz
        7  => 18961,  -- Mi 5  (E5)  -> ~1318,51 Hz
        8  => 17897,  -- Fá 5  (F5)  -> ~1396,91 Hz
        9  => 16892,  -- Fá# 5 (F#5) -> ~1479,98 Hz
        10 => 15944,  -- Sol 5 (G5)  -> ~1567,98 Hz
        11 => 15049,  -- Sol# 5(G#5) -> ~1661,22 Hz
        12 => 14205   -- Lá 5  (A5)  ->  1760,00 Hz
    );

    signal counter    : integer range 0 to 30000 := 0;
    signal max_count  : integer range 0 to 30000 := 247; -- Padrão: B3 tinha q ser 246,97 mas inteiro tem q ser inteiro
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
