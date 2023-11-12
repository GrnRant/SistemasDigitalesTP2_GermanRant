ghdl -a utilities.vhd
ghdl -a float_adder.vhd
ghdl -a float_adder_tb.vhd
ghdl -m float_adder_tb
ghdl -r float_adder_tb --vcd=float_adder_tb.vcd