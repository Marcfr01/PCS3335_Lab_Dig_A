library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Bin_to_7Seg is
    Port ( 
        bin_in : in  std_logic_vector (9 downto 0); -- Entrada binária (máx 1023)
        seg3   : out std_logic_vector (6 downto 0); -- Display dos Milhares (0 ou 1)
        seg2   : out std_logic_vector (6 downto 0); -- Display das Centenas
        seg1   : out std_logic_vector (6 downto 0); -- Display das Dezenas
        seg0   : out std_logic_vector (6 downto 0)  -- Display das Unidades
    );
end Bin_to_7Seg;

architecture Behavioral of Bin_to_7Seg is

    -- Função auxiliar para decodificar BCD para 7 Segmentos (Catodo Comum)
    -- Mapeamento: a b c d e f g (índices 6 5 4 3 2 1 0)
    function decode_7seg(bcd : unsigned(3 downto 0)) return std_logic_vector is
        variable seg : std_logic_vector(6 downto 0);
    begin
        case bcd is
            when "0000" => seg := "1111110"; -- 0
            when "0001" => seg := "0110000"; -- 1
            when "0010" => seg := "1101101"; -- 2
            when "0011" => seg := "1111001"; -- 3
            when "0100" => seg := "0110011"; -- 4
            when "0101" => seg := "1011011"; -- 5
            when "0110" => seg := "1011111"; -- 6
            when "0111" => seg := "1110000"; -- 7
            when "1000" => seg := "1111111"; -- 8
            when "1001" => seg := "1111011"; -- 9
            when others => seg := "0000000"; -- Apaga se inválido
        end case;
        return seg;
    end function;

begin

    process(bin_in)
        variable temp_bin : std_logic_vector(9 downto 0);
        variable bcd      : unsigned(15 downto 0);
    begin
        -- Inicializa as variáveis
        temp_bin := bin_in;
        bcd      := (others => '0');

        -- Algoritmo Double Dabble (Shift and Add 3)
        for i in 0 to 9 loop
            
            -- Antes de dar o shift, verifica se algum dígito BCD é >= 5. Se for, soma 3.
            if bcd(3 downto 0) > 4 then
                bcd(3 downto 0) := bcd(3 downto 0) + 3;
            end if;
            
            if bcd(7 downto 4) > 4 then
                bcd(7 downto 4) := bcd(7 downto 4) + 3;
            end if;
            
            if bcd(11 downto 8) > 4 then
                bcd(11 downto 8) := bcd(11 downto 8) + 3;
            end if;
            
            if bcd(15 downto 12) > 4 then
                bcd(15 downto 12) := bcd(15 downto 12) + 3;
            end if;

            -- Deslocamento (Shift left) de 1 bit para a esquerda
            bcd := bcd(14 downto 0) & temp_bin(9);
            temp_bin := temp_bin(8 downto 0) & '0';
            
        end loop;

        -- Separa os 16 bits nas 4 saídas passando pela função decodificadora
        seg0 <= decode_7seg(bcd(3 downto 0));   -- Unidades
        seg1 <= decode_7seg(bcd(7 downto 4));   -- Dezenas
        seg2 <= decode_7seg(bcd(11 downto 8));  -- Centenas
        seg3 <= decode_7seg(bcd(15 downto 12)); -- Milhares

    end process;

end Behavioral;
