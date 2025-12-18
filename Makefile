\
VERILATOR ?= verilator
CXXFLAGS  ?= -O2 -std=c++17

IN_DIM  ?= 64
OUT_DIM ?= 16

# --------------------
# Full accelerator sim
# --------------------
TOP_ACCEL := qnn_accel_top
RTL_ACCEL := rtl/qnn_accel_top.sv \
             rtl/scheduler_ctrl.sv \
             rtl/mixed_precision_ctrl.sv \
             rtl/dense_engine.sv \
             rtl/mac_array.sv \
             rtl/mac_unit.sv \
             rtl/activation_relu.sv \
             rtl/quantizer_unit.sv \
             rtl/memory_bank.sv \
             rtl/conv2d_stub.sv

TB_DENSE  := tb/tb_dense.cpp

.PHONY: sim
sim: obj_dir/V$(TOP_ACCEL)
	./obj_dir/V$(TOP_ACCEL)

obj_dir/V$(TOP_ACCEL): $(RTL_ACCEL) $(TB_DENSE)
	$(VERILATOR) -Wall --sv --cc $(RTL_ACCEL) --exe $(TB_DENSE) \
	  -CFLAGS "$(CXXFLAGS) -DIN_DIM=$(IN_DIM) -DOUT_DIM=$(OUT_DIM)" \
	  --top-module $(TOP_ACCEL) \
	  -GIN_DIM=$(IN_DIM) -GOUT_DIM=$(OUT_DIM)
	$(MAKE) -C obj_dir -f V$(TOP_ACCEL).mk

# --------------------
# Unit: quantizer
# --------------------
TOP_Q := quantizer_unit
RTL_Q := rtl/quantizer_unit.sv
TB_Q  := tb/tb_quantizer.cpp

.PHONY: sim_quantizer
sim_quantizer: obj_dir/V$(TOP_Q)
	./obj_dir/V$(TOP_Q)

obj_dir/V$(TOP_Q): $(RTL_Q) $(TB_Q)
	$(VERILATOR) -Wall --sv --cc $(RTL_Q) --exe $(TB_Q) \
	  -CFLAGS "$(CXXFLAGS)" \
	  --top-module $(TOP_Q)
	$(MAKE) -C obj_dir -f V$(TOP_Q).mk

# --------------------
# Unit: mac
# --------------------
TOP_M := mac_unit
RTL_M := rtl/mac_unit.sv
TB_M  := tb/tb_mac.cpp

.PHONY: sim_mac
sim_mac: obj_dir/V$(TOP_M)
	./obj_dir/V$(TOP_M)

obj_dir/V$(TOP_M): $(RTL_M) $(TB_M)
	$(VERILATOR) -Wall --sv --cc $(RTL_M) --exe $(TB_M) \
	  -CFLAGS "$(CXXFLAGS)" \
	  --top-module $(TOP_M)
	$(MAKE) -C obj_dir -f V$(TOP_M).mk

.PHONY: clean
clean:
	rm -rf obj_dir *.vcd
