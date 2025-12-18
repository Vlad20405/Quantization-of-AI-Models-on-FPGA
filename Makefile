\
TOP      := qnn_dense_top
RTL      := rtl/$(TOP).sv
TB       := tb/tb_qnn.cpp

VERILATOR ?= verilator
CXXFLAGS  ?= -O2 -std=c++17

IN_DIM  ?= 64
OUT_DIM ?= 16

.PHONY: sim
sim: obj_dir/V$(TOP)
	./obj_dir/V$(TOP)

obj_dir/V$(TOP): $(RTL) $(TB)
	$(VERILATOR) -Wall --sv --cc $(RTL) --exe $(TB) \
	  -CFLAGS "$(CXXFLAGS) -DIN_DIM=$(IN_DIM) -DOUT_DIM=$(OUT_DIM)" \
	  --top-module $(TOP) \
	  -GIN_DIM=$(IN_DIM) -GOUT_DIM=$(OUT_DIM)
	$(MAKE) -C obj_dir -f V$(TOP).mk

.PHONY: clean
clean:
	rm -rf obj_dir *.vcd
