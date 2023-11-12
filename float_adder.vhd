library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.utils.all;

entity float_adder is
    generic (
        NE : natural := 8;
        NF : natural := 23);
    port (
        x_i : in std_logic_vector((NE + NF) downto 0);
        y_i : in std_logic_vector((NE + NF) downto 0);
        res_o : out std_logic_vector((NE + NF) downto 0)
    );
end float_adder;

architecture float_adder_arch of float_adder is

    --Bits de signo de cada uno de los registros
    signal sa : std_logic; --Bit signo del número mayor
    signal sb : std_logic; --Bit signo de número menor 
    signal sp : std_logic; --Bit signo parcial
    signal sr : std_logic; --Bit signo resultante

    --Bits de exponente de cada uno de los registros
    signal ea : unsigned(NE - 1 downto 0) := (others => '0'); --Exponente del número mayor
    signal eb : unsigned(NE - 1 downto 0) := (others => '0'); --Exponente del número menor
    signal ep : integer := 0; --Exponente parcial (tiene 1 bit más para verificar saturación) 
    signal er : unsigned(NE - 1 downto 0) := (others => '0'); --Exponente resultante si no  hay saturación
    signal edif: integer := 0; --Diferencia entre el exponente mayor y el menor
    signal esat : unsigned(NE - 1 downto 0) := (others => '0'); --Exponente resultante si hay saturación
    constant ezero : unsigned(NE - 1 downto 0) := (others => '0'); --Constante usada cuando resultado es cero

    --Bits de mantisa de cada uno de los registros
    signal ma : unsigned(NF - 1 downto 0) := (others => '0'); --Mantisa del número mayor
    signal mb : unsigned(NF - 1 downto 0) := (others => '0'); --Mantisa del número menor
    signal mp : unsigned(NF - 1 downto 0) := (others => '0'); --Mantisa resultante cuando no hay saturación
    constant msat : unsigned(NF - 1 downto 0) := (others => '1'); --Usada cuando hay saturación
    constant mzero : unsigned(NF - 1 downto 0) := (others => '0'); --Usada cuando resultado es cero
    signal mr : unsigned(NF - 1 downto 0) := (others => '0'); --Mantisa resultante
 
    --Auxiliares
    signal aligna: unsigned(NF + 1 downto 0) := (others => '0'); --Alineación del mayor (solo se concatena '1') 
    signal alignb: unsigned(NF + 1 downto 0) := (others => '0'); --Alineación del menor
    signal sum: unsigned(NF + 1 downto 0) := (others => '0'); --Resultado de la suma/resta (sin signo)
    signal sum_shifted: unsigned(NF + 1 downto 0) := (others => '0'); --Resultado de la suma/resta shifteada hasta primer '1'
    signal lead: integer := 0; --Cantidad de ceros que hay hasta el primer '1' de suma de mantisas alineadas
    signal sat: std_logic := '0';

begin
    --Inicialización exponente saturación
    esat(NE - 1 downto 1) <= (others => '1');
    esat(0) <= '0';

    --Se asigna el menor a "b" a y el mayor a "a":
    P_SEL_MENOR_MAYOR : process (x_i, y_i)
        variable sx : std_logic; --Bit signo de x_i
        variable sy : std_logic; --Bit signo de y_i
        variable ex : unsigned(NE - 1 downto 0); --Exponente de x_i
        variable ey : unsigned(NE - 1 downto 0); --Exponente de y_i
        variable mx : unsigned(NF - 1 downto 0); --Mantisa de cada una de x_i
        variable my : unsigned(NF - 1 downto 0); --Mantisa de cada una de y_i

    begin
        sx := x_i(NF + NE);
        sy := y_i(NF + NE);
        ex := unsigned(x_i((NE + NF) - 1 downto NF));
        ey := unsigned(y_i((NE + NF) - 1 downto NF));
        mx := unsigned(x_i(NF - 1 downto 0));
        my := unsigned(y_i(NF - 1 downto 0));

        if (ex & mx) > (ey & my) then
            sa <= sx;
            ea <= ex;
            ma <= mx;
            sb <= sy;
            eb <= ey;
            mb <= my;
        else
            sa <= sy;
            ea <= ey;
            ma <= my;
            sb <= sx;
            eb <= ex;
            mb <= mx;
        end if;
    end process;

    --Se alinean los números:
    edif <= to_integer(ea - eb);
    aligna(NF downto 0) <= '1' & ma; --Mantisa mayor alineada con 1 explícito
    alignb(NF downto 0) <= (('1' & mb) srl edif) when (edif <= NF) else (others => '0'); --Mantisa menor alineada con 1 explícito

    --Se realiza la suma/resta:
    sum <= (aligna + alignb) when (sa = sb) else (aligna - alignb);
    sp <= sa; --El signo del número resultante siempre va a ser igual al del mayor

    --Se obtiene el exponente y mantisas parciales:
    lead <= get_lead(sum(NF downto 0));  --Si hubo carry out lead <= -1
    ep <= to_integer(ea) + 1 when sum(NF+1) = '1' else to_integer(ea) - lead; --Desplazamiento del exponente
    --Se hace desplazamientos de suma dependiendo de los dos primeros bits de sum 
    sum_shifted <= sum when sum(NF+1 downto NF) = "11" else 
                    sum srl 1 when sum(NF+1 downto NF) = "10" else 
                    sum sll lead;
    mp <= sum_shifted((NF - 1) downto 0); --Mantisa parcial, -1 en el rango para sacar el 1 implícito

    --Verificación de saturación y obtención de valores resultantes
    sr <= sp;
    er <= ezero when (ep < 0) else esat when (ep > 254) else to_unsigned(ep, NE);
    mr <= mzero when (ep < 0) else msat when (ep > 254) else mp;
    sat <= '1' when (ep < 0 or ep > 254) else '0';
    
    --Salida final
    res_o <= (std_logic_vector(sr & er & mr));

end float_adder_arch;