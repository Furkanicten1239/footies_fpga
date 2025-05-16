# Makefile for Verilator simulation

TOP_MODULE = fighting_game_vga
VERILOG_SRCS = \
    fighting_game_vga.v \
    fsm.v \
    vga_render.v \
    vga_driver.v \
    hitlogic.v \
    health_logic.v \
    game_control.v \
    hex_decoder.v

all: sim

sim:
	verilator -Wall --cc $(VERILOG_SRCS) --top-module $(TOP_MODULE) --exe main.cpp
	make -C obj_dir -j -f V$(TOP_MODULE).mk V$(TOP_MODULE)
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir *.vcd
