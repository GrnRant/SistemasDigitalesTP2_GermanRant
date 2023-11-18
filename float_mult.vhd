library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity float_mult is
    generic (
        NE : natural := 8;
        NF : natural := 23);
    port (
        x_i : in std_logic_vector((NE + NF) downto 0);
        y_i : in std_logic_vector((NE + NF) downto 0);
        res_o : out std_logic_vector((NE + NF) downto 0)
    );
end float_mult;

architecture float_mult_arch of float_mult is

    --Bits de signo de cada uno de los registros
    signal sx : std_logic; --Bit signo de x_i
    signal sy : std_logic; --Bit signo de y_i
    signal sr : std_logic; --Bit signo resultante

    --Bits de exponente de cada uno de los registros
    signal ex : unsigned(NE - 1 downto 0); --Exponente de x_i
    signal ey : unsigned(NE - 1 downto 0); --Exponente de y_i
    signal ep : integer; --Exp parcial obtenido a partir de ex y ey
    signal er_int : integer := 0; --Exp resultante como entero
    signal er : unsigned(NE - 1 downto 0); --Exponente resultante si no  hay saturación
    signal emax : unsigned(NE - 1 downto 0); --Exponente resultante si hay saturación
    signal emin : unsigned(NE - 1 downto 0); --Exponente resultante si hay saturación
    signal ezero : unsigned(NE - 1 downto 0); --Constante usada cuando resultado es cero
    constant esat : unsigned(NE - 1 downto 0) := ('0', others => '1');

    --Bits de mantisa de cada uno de los registros
    signal mx : unsigned(NF - 1 downto 0); --Mantisa de cada una de x_i
    signal my : unsigned(NF - 1 downto 0); --Mantisa de cada una de y_i
    signal mp1 : unsigned(2 * NF + 1 downto 0); --Mantisa parcial no normalizada
    signal mp2 : unsigned(NF - 1 downto 0);
    signal mr : unsigned(NF - 1 downto 0); --Mantisa resultante cuando no hay saturación
    signal mmax : unsigned(NF - 1 downto 0); --Usada cuando hay saturación
    signal mzero : unsigned(NF - 1 downto 0);

    --Auxiliares
    signal ov : std_logic := '0'; --Bit de overflow de la mantisa
    constant exc : unsigned(NE - 1 downto 0) := ('0', others => '1'); --Excedente del exponente (bias)
    signal sat : std_logic := '0'; --Señal interna de saturación

begin
    --Inicialización exponente saturación, de mantisas, exponentes y bits de signo de entrada
    sx <= x_i(NF + NE);
    sy <= y_i(NF + NE);

    emax(NE - 1 downto 1) <= (others => '1');
    emax(0) <= '0';
    emin(NE - 1 downto 0) <= to_unsigned(1, NE);
    ex <= unsigned(x_i((NE + NF) - 1 downto NF));
    ey <= unsigned(y_i((NE + NF) - 1 downto NF));
    ezero <= (others => '0');

    mx <= unsigned(x_i(NF - 1 downto 0));
    my <= unsigned(y_i(NF - 1 downto 0));
    mmax <= (others => '1');
    mzero <= (others => '0');

    --Operaciones parciales para la mantisa
    mp1 <= ('1' & mx) * ('1' & my);
    --Overflow = al bit más significativo
    ov <= mp1(2*NF + 1); 

    --Resultados parciales
    mp2 <= mp1(2 * NF downto NF + 1) when mp1(2*NF + 1) = '1' 
            else mp1(2 * NF - 1 downto NF); --Normalización de mantisa
    ep <= (to_integer(ex) + to_integer(ey) - to_integer(exc) + 1) when mp1(2*NF + 1) = '1'
            else to_integer(ex) + to_integer(ey) - to_integer(exc); --Resultado parcial exponente

    --Resultados finales
    --Operaciones para el signo
    sr <= '0' when (ep < to_integer(emin)) or (mx = 0 and ex = 0) or (my = 0 and ey = 0) else sx xor sy;
    --Resultado exponente
    er_int <= to_integer(emax) when ep > to_integer(emax) 
                else to_integer(ezero) when (ep < to_integer(emin)) or (mx = 0 and ex = 0) or (my = 0 and ey = 0) 
                else ep;
    er <= to_unsigned(er_int, NE);
    --Resultado mantisa
    mr <= mmax when ep > to_integer(emax) 
            else mzero when (ep < to_integer(emin)) or (mx = 0 and ex = 0) or (my = 0 and ey = 0) 
            else mp2;

    --Salida del resultado final (concatenación de signo, exponente, mantisa resultantes)
    res_o <= std_logic_vector(sr & er & mr);

end float_mult_arch;