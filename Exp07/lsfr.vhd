library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--Linear-feedback shift register
-- registrador de feedback que gera diferentes sequencias com base na seed de entrada
-- capaz de realizar uma sequencia de 2^n-1 elementos ate se repetir
entity lsfr is 
    generic(
         n : integer := 3 -- numero de bits
    );
    port (
        clock  : in std_logic;
        enable : in std_logic;
        reset  : in std_logic;
        min    : in std_logic_vector(n-1 downto 0);
        max    : in std_logic_vector(n-1 downto 0);
        seed   : in std_logic_vector(n-1 downto 0);
        d_out  : out std_logic_vector(n-1 downto 0)
    );
end entity lsfr;
  
architecture arch of lsfr is
    signal temp : std_logic_vector(n-1 downto 0);
    
    begin
        process(clock, reset, enable)
            begin
                if reset = '1'
                    if unsigned(seed) = 0 then
                        temp <= (0 => '1', others => '0');
                    else
                         temp <= seed;
                    end if;
                elsif clock'event and clock = '1' then
                    if enable = '1' then
                        temp <= temp(n-2 downto 0) & (temp(n-3) xor temp(n-2) xor temp(n-1)); --shift para direita e logica XOR para bit menos significativo 
                    end if;
                end if;
        end process;
    


    d_out <= temp when (unsigned(min) <= unsigned(temp) and unsigned(temp) <= unsigned(max)) else
             std_logic_vector((unsigned(max) + unsigned(min)) / 2); -- caso temp esteja fora do intervalo [min, max] a saida e a metade do intervalo

end architecture;
