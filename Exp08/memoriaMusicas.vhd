library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;

entity memoriaMusicas is
    generic (
        addressSize : natural := 8;
        dataSize    : natural := 8;
        datFileName : string  := "memInstr_conteudo.dat"
    );
    port (
        -- FIX: portas trocadas de bit_vector para std_logic_vector
        --      para compatibilidade direta com o restante do projeto
        addr : in  std_logic_vector(addressSize - 1 downto 0);
        data : out std_logic_vector(dataSize    - 1 downto 0)
    );
end entity memoriaMusicas;

architecture rtl of memoriaMusicas is

    -- Memoria interna mantida como bit_vector porque std.textio.read()
    -- so suporta leitura direta de bit_vector (nao de std_logic_vector).
    -- A conversao para std_logic_vector e feita apenas na saida.
    type mem_type is array (0 to (2**addressSize) - 1) of bit_vector(dataSize - 1 downto 0);

    impure function init_mem(arquiveName : in string) return mem_type is
        file     arquivo  : text open read_mode is arquiveName;
        variable linha    : line;
        variable temp_bv  : bit_vector(dataSize - 1 downto 0);
        variable temp_mem : mem_type;
    begin
        for i in mem_type'range loop
            readline(arquivo, linha);
            read(linha, temp_bv);
            temp_mem(i) := temp_bv;
        end loop;
        return temp_mem;
    end function;

    function bits_to_integer(bv : bit_vector) return integer is
        variable result : integer := 0;
        variable idx    : integer := 0;
    begin
        for i in bv'reverse_range loop
            if bv(i) = '1' then
                result := result + (2**idx);
            end if;
            idx := idx + 1;
        end loop;
        return result;
    end function;

    signal mem : mem_type := init_mem(datFileName);

begin
    -- Converte o endereco de entrada (std_logic_vector -> bit_vector),
    -- acessa a memoria, e converte a saida (bit_vector -> std_logic_vector)
    data <= to_stdlogicvector(mem(bits_to_integer(to_bitvector(addr))));

end architecture;
