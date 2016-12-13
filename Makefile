SIM=iverilog -I rtl/verilog

.PHONY: test

test:
	$(SIM) -Wall bench/verilog/S64X7.v rtl/verilog/S64X7.v rtl/verilog/alu.v
	vvp -n a.out
