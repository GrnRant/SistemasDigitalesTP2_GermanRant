library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package utils is

    function get_lead(x: unsigned) return integer;

    function shift_left(x: unsigned; shift: integer) return unsigned;

    function shift_right(x: unsigned; shift: integer) return unsigned;

    function shift_right_arith(x: unsigned; shift: integer) return unsigned;

end utils;

package body utils is

    function get_lead(x: unsigned) return integer is
        variable lead : integer := 0;
        begin
            for i in  (x'length - 1) downto 0 loop
                if x(i) = '1' then
                    return lead;
                end if;
                lead := lead + 1;
            end loop;
        return x'length - 1;
    end get_lead;

    function shift_left(x: unsigned; shift: integer) return unsigned is
        begin
            return x sll shift;
    end shift_left;

    function shift_right(x: unsigned; shift: integer) return unsigned is
        begin
            return x srl shift;
    end shift_right;

    function shift_right_arith(x: unsigned; shift: integer) return unsigned is
        variable aux: unsigned(x'length - 1 downto 0) := (others => '0');
        begin
            aux(x'length - 1 downto shift) := (others => '1'); 
            return (x srl shift) or aux;
    end shift_right_arith;

end utils;