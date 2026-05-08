
library ieee;
use std.textio.all;

entity memoriaMusicas is
	generic (
		addressSize : natural := 8;
		dataSize    : natural := 8;
		datFileName : string := "memInstr_conteudo.dat"
	);
	port (
		addr : in bit_vector (addressSize - 1 downto 0);
		data : out bit_vector (dataSize - 1 downto 0)
	);
end entity memoriaMusicas;

architecture rtl of memoriaMusicas is 
-- tipo memória
type mem_type is array (0 to (2**addressSize) - 1) of bit_vector (dataSize - 1 downto 0); -- 2^n - 1 posicoes de memoria, com k bits de largura

-- funcao de iniciar a memoria
impure function init_mem(arquiveName : in string) return mem_type is 
	file 		arquivo 	: text open read_mode is arquiveName;
	variable linha 	: line;
	variable temp_bv  : bit_vector(dataSize-1 downto 0);
	variable temp_mem : mem_type;
	begin
		for i in mem_type'range loop
			readline(arquivo, linha);
			read(linha, temp_bv);
			temp_mem(i) := temp_bv;
		end loop;
		return temp_mem;
	end;

-- funcao de conversão bit_vector para integer
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
	
signal mem : mem_type := init_mem(datFileName); -- inicializo a memora
begin
	data <= mem(bits_to_integer(addr));

end architecture;
