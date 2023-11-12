library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity delay_gen is
	generic (
		N : natural := 8;
		DELAY : natural := 0
	);
	port (
		clk : in std_logic;
		A : in unsigned(N - 1 downto 0);
		B : out unsigned(N - 1 downto 0)
	);
end;

architecture del of delay_gen is
	signal aux : integer := 0;

begin
	P_RETARDO : process (clk)
	begin
		if rising_edge(clk) then
			if aux = DELAY then
				aux <= 0;
				B <= A;
			else
				aux <= aux + 1;
			end if;
		end if;
	end process;
end del;