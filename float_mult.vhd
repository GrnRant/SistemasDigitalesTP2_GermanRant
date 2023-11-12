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
    signal ep1 : unsigned(NE downto 0) := (others => '0'); --Exp parcial obtenido a partir de ex y ey
    signal ep2 : unsigned(NE downto 0) := (others => '0'); --Exp parcial usado para decidir si es cero el resultado
    signal er : unsigned(NE - 1 downto 0); --Exponente resultante si no  hay saturación
    signal emax : unsigned(NE - 1 downto 0); --Exponente resultante si hay saturación
    signal ezero : unsigned(NE - 1 downto 0); --Constante usada cuando resultado es cero
    constant esat : unsigned(NE downto 0) := ('0', others => '1');

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
    emax <= (others => '1');
    emax(0) <= '0';
    sx <= x_i(NF + NE);
    sy <= y_i(NF + NE);
    ex <= unsigned(x_i((NE + NF) - 1 downto NF));
    ey <= unsigned(y_i((NE + NF) - 1 downto NF));
    emax(NE - 1 downto 1) <= (others => '1');
    emax(0) <= '0';
    ezero <= (others => '0');
    mx <= unsigned(x_i(NF - 1 downto 0));
    my <= unsigned(y_i(NF - 1 downto 0));
    mmax <= (others => '1');
    mzero <= (others => '0');

    --Operaciones para el signo
    sr <= sx xor sy;

    --Operaciones para la mantisa
    mp1 <= ('1' & mx) * ('1' & my);
    ov <= mp1(2 * NF + 1); --Overflow = al bit más significativo
    mp2 <= mp1(2 * NF downto NF + 1) when ov = '1' else
        mp1(2 * NF - 1 downto NF); --Se considera ov y se saca 1 implícito
    mr <= mzero when ((mx = 0 and ex = 0) or (my = 0 and ey = 0)) else mp2;

    --Operaciones para el exponente
    ep1 <= ('0' & ex) + ('0' & ey) - ('0' & exc);
    ep2 <= ep1 when ov = '0' else ep1 + 1; --Se suma el overflow si es que hay
    er <= ezero when ((mx = 0 and ex = 0) or (my = 0 and ey = 0)) else
     ep2(NE - 1 downto 0); --Si mx = 0 o my = 0 entonces exponente = 0

    --Verificación de saturación
    --Si el exponente supera emax (valor máximo) entonces hay saturación
    sat <= '1' when (ep2 >= esat) else '0';

    --Salida del resultado final (concatenación de signo, exponente, mantisa resultantes)
    res_o <= std_logic_vector(sr & er & mr) when sat = '0' else
        std_logic_vector(sr & emax & mmax);

end float_mult_arch;