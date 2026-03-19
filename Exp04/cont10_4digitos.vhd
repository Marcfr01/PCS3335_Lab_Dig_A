library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity cont10_4digitos is
port (
	clock, clear, enable   : in std_logic;
	Q0, Q1, Q2, Q3         : out std_logic_vector(3 downto 0);
	RCO 	           : out std_logic);
end entity cont10_4digitos;

architecture arch of cont10_4digitos is
  
  component cont10 is
      port (
          clock   : in  std_logic;
          clear   : in  std_logic;
          enable  : in  std_logic;
          Q       : out std_logic_vector(3 downto 0);
          RCO     : out std_logic);
  end component;
  
  -- sinais c0
  signal rco0 : std_logic := '0';
  
  --sinais c1
  signal enable1 : std_logic := '0';
  signal rco1 : std_logic := '0';
  
  --sinais c2
  signal enable2 : std_logic := '0';
  signal rco2 : std_logic := '0';
  
  --sinais c3
  signal enable3 : std_logic := '0';
  signal rco3 : std_logic := '0';
  
  
  begin
 
	c0 : cont10
	port map(
          clock   =>  clock, 
          clear   =>  clear,
          enable  =>  enable,
          Q       =>  Q0,
          RCO     =>  rco0);
		
	c1 : cont10
	port map(
          clock   =>  clock, 
          clear   =>  clear,
          enable  =>  enable1,
          Q       =>  Q1,
          RCO     =>  rco1);

	c2 : cont10
	port map(
          clock   =>  clock, 
          clear   =>  clear,
          enable  =>  enable2,
          Q       =>  Q2,
          RCO     =>  rco2);
			
	c3 : cont10
	port map(
          clock   =>  clock, 
          clear   =>  clear,
          enable  =>  enable3,
          Q       =>  Q3,
          RCO     =>  rco3);
		
	enable1 <= enable and rco0;
	enable2 <= enable and rco0 and rco1;
	enable3 <= enable and rco0 and rco1 and rco2;

        RCO <= rco0 and rco1 and rco2 and rco3;
	
end architecture;