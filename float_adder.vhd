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
    signal sx : std_logic; --Bit signo de x_i
    signal sy : std_logic; --Bit signo de y_i

    --Bits de exponente de cada uno de los registros
    signal ea : unsigned(NE - 1 downto 0) := (others => '0'); --Exponente del número mayor
    signal eb : unsigned(NE - 1 downto 0) := (others => '0'); --Exponente del número menor
    signal ep : integer := 0; --Exponente parcial (tiene 1 bit más para verificar saturación) 
    signal er : unsigned(NE - 1 downto 0) := (others => '0'); --Exponente resultante si no  hay saturación
    signal edif: integer := 0; --Diferencia entre el exponente mayor y el menor
    signal esat : unsigned(NE - 1 downto 0) := (others => '0'); --Exponente resultante si hay saturación
    constant ezero : unsigned(NE - 1 downto 0) := (others => '0'); --Constante usada cuando resultado es cero
    signal ex : unsigned(NE - 1 downto 0); --Exponente de x_i
    signal ey : unsigned(NE - 1 downto 0); --Exponente de y_i

    --Bits de mantisa de cada uno de los registros
    signal ma : unsigned(NF - 1 downto 0) := (others => '0'); --Mantisa del número mayor
    signal mb : unsigned(NF - 1 downto 0) := (others => '0'); --Mantisa del número menor
    signal mp : unsigned(NF - 1 downto 0) := (others => '0'); --Mantisa resultante cuando no hay saturación
    constant msat : unsigned(NF - 1 downto 0) := (others => '1'); --Usada cuando hay saturación
    constant mzero : unsigned(NF - 1 downto 0) := (others => '0'); --Usada cuando resultado es cero
    signal mr : unsigned(NF - 1 downto 0) := (others => '0'); --Mantisa resultante
    signal mx : unsigned(NF - 1 downto 0); --Mantisa de cada una de x_i
    signal my : unsigned(NF - 1 downto 0); --Mantisa de cada una de y_i
 
    --Auxiliares
    signal aligna: unsigned(NF + (2**NE-2) + 1 downto 0) := (others => '0'); --Alineación del mayor (solo se concatena '1') 
    signal alignb: unsigned(NF + (2**NE-2) + 1 downto 0) := (others => '0'); --Alineación del menor
    signal sum: unsigned(NF + (2**NE-2) + 1 downto 0) := (others => '0'); --Resultado de la suma/resta (sin signo)
    signal sum_shifted: unsigned(NF + 1 downto 0) := (others => '0'); --Resultado de la suma/resta shifteada hasta primer '1'
    signal lead: integer := 0; --Cantidad de ceros que hay hasta el primer '1' de suma de mantisas alineadas

begin
    sx <= x_i(NF + NE);
    sy <= y_i(NF + NE);
    ex <= unsigned(x_i((NE + NF) - 1 downto NF));
    ey <= unsigned(y_i((NE + NF) - 1 downto NF));
    mx <= unsigned(x_i(NF - 1 downto 0));
    my <= unsigned(y_i(NF - 1 downto 0));

    --Inicialización exponente saturación
    esat(NE - 1 downto 1) <= (others => '1');
    esat(0) <= '0';

    --Se asigna el menor a "b" a y el mayor a "a":
    sa <= sx when ((ex & mx) > (ey & my)) else sy;
    ea <= ex when ((ex & mx) > (ey & my)) else ey;
    ma <= mx when ((ex & mx) > (ey & my)) else my;
    sb <= sy when ((ex & mx) > (ey & my)) else sx;
    eb <= ey when ((ex & mx) > (ey & my)) else ex;
    mb <= my when ((ex & mx) > (ey & my)) else mx;

    edif <= to_integer(ea - eb);
    --Se alinean los números:
    P_ALINACION: process(ma, mb, edif)
        variable auxa:  unsigned(NF + (2**NE-2) + 1 downto 0) := (others => '0');
        variable auxb:  unsigned(NF + (2**NE-2) + 1 downto 0) := (others => '0');
    begin
        auxa(NF + 1 downto 0) := "01" & ma; --Mantisa mayor alineada con 1 explícito
        auxa := auxa sll edif;
        auxb(NF + edif + 1 downto NF + 2) := (others => '0');
        auxb(NF + 1 downto 0) := "01" & mb; --Mantisa mayor alineada con 1 explícito

        aligna <= auxa;
        alignb <= auxb;
    end process;

    --Se realiza la suma/resta:
    sum <= (aligna + alignb) when (sa = sb) else (aligna - alignb);
    sp <= sa; --El signo del número resultante siempre va a ser igual al del mayor

    --Se obtiene el exponente y mantisas parciales:
    lead <= get_lead(sum(NF + edif downto 0));
    ep <= to_integer(ea) + 1 when sum(NF + edif + 1) = '1' and (sa = sb) else to_integer(ea) - lead;

    sum_shifted <= sum(NF + edif + 1 downto edif) when sum(NF + edif + 1 downto NF + edif) = "11" 
                    else sum(NF + edif + 1 downto edif) srl 1 when sum(NF + edif + 1 downto NF + edif) = "10" 
                    else sum(NF + edif + 1 downto edif) sll lead when (lead < NF);

    mp <= sum_shifted((NF - 1) downto 0); --Mantisa parcial, -1 en el rango para sacar el 1 implícito

    --Verificación de saturación y obtención de valores resultantes
    sr <= sp;
    er <= ezero when (ep < 0) else esat when (ep > to_integer(esat)) else to_unsigned(ep, NE);
    mr <= mzero when (ep < 0) else msat when (ep > to_integer(esat)) else mp;
     
    --Salida final
    res_o <= (std_logic_vector(sr & er & mr));

end float_adder_arch;
