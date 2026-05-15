entity pwm_generator is
    Port (
        clk   : in  STD_LOGIC;
        reset : in  STD_LOGIC;
        duty  : in  STD_LOGIC_VECTOR (7 downto 0);
        pwm   : out STD_LOGIC
    );
end pwm_generator;

architecture Behavioral of pwm_generator is
    signal counter : unsigned(7 downto 0) := (others => '0');
begin
    process(clk, reset)
    begin
        if reset = '1' then
            counter <= (others => '0');
            pwm <= '0';
        elsif rising_edge(clk) then
            counter <= counter + 1;
            if counter < unsigned(duty) then
                pwm <= '1';
            else
                pwm <= '0';
            end if;
        end if;
    end process;
end Behavioral;
