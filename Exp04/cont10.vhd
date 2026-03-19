-------------------------------------------------------------------------------
-- Arquivo   : cont10.vhd
-------------------------------------------------------------------------------
-- Descricao : Contador decimal com clear assincrono      
-------------------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor                               Descricao
--     20/02/2026  1.0     Edson Midorikawa e Felipe Valencia  versao inicial
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cont10 is
    port (
        clock   : in  std_logic;
        clear   : in  std_logic;
        enable  : in  std_logic;
        Q       : out std_logic_vector(3 downto 0);
        RCO     : out std_logic
    );
end cont10;

architecture arch of cont10 is
    signal IQ: integer range 0 to 9;
begin

    process (clock, clear, enable)
    begin
        if clear = '1' then         -- clear assincrono
            IQ <= 0;
            
        elsif clock'event and clock='1' then
            if enable = '1' then
                if IQ = 9 then
                    IQ <= 0;
                else
                    IQ <= IQ + 1;
                end if;
            end if;
        end if;    
    end process;	
  
    RCO <= '1' when IQ = 9 else '0'; -- fim de contagem
    Q   <= std_logic_vector(to_unsigned(IQ, Q'length));  -- saida Q
end architecture;