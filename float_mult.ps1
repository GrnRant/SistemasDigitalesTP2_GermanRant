ghdl -a float_mult.vhd
ghdl -a float_mult_tb.vhd
ghdl -m float_mult_tb
ghdl -r float_mult_tb --vcd=float_mult_tb.vcd