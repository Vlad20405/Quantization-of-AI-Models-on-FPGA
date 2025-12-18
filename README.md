# Quantization of AI Models on FPGA — Implementation (SystemVerilog + Verilator)

This repository contains a **modular, configurable FPGA-style accelerator** for quantized NN inference,
aligned with the architecture described in the project documentation:
- **Quantizer Unit** (INT8 / INT4 / BIN)
- **Integer MAC blocks / MAC Array**
- **Dense (Fully Connected) Engine**
- **Quantized Activation (ReLU)**
- **Mixed Precision Controller**
- **(Simplified) Memory Banks + Scheduler/Control FSM**
- Self-checking **Verilator** simulation testbench

> Note: FP32→INTx quantization is represented in hardware as **fixed-point to INTx** using a shift-based scale.
> This is hardware-realistic and matches the rounding+clipping behavior described in the documentation.

## Requirements (WSL/Ubuntu recommended on Windows)
```bash
sudo apt update
sudo apt install -y make g++ verilator
```

## Run simulations
Dense accelerator (INT8/INT4/BIN):
```bash
make sim
```

Optional: run module-level unit tests:
```bash
make sim_quantizer
make sim_mac
```

## Project structure
- `rtl/quantizer_unit.sv`       — Quantizer Unit (shift-based scale, rounding, clipping, binarization)
- `rtl/mac_unit.sv`             — MAC primitive (INT8/INT4/BIN)
- `rtl/mac_array.sv`            — Parameterizable PE array (default 1 PE)
- `rtl/activation_relu.sv`      — Quantized ReLU
- `rtl/mixed_precision_ctrl.sv` — Precision selector (per-layer / runtime)
- `rtl/memory_bank.sv`          — Simple BRAM-like bank (behavioral)
- `rtl/dense_engine.sv`         — Dense engine (sequential accumulate, optional PE>1)
- `rtl/scheduler_ctrl.sv`       — Control FSM coordinating the engines
- `rtl/qnn_accel_top.sv`        — Top-level integration
- `tb/tb_dense.cpp`             — Self-checking TB for the full accelerator top
- `tb/tb_quantizer.cpp`         — Unit TB for quantizer
- `tb/tb_mac.cpp`               — Unit TB for mac

## Key parameters
You can override dimensions at build time:
```bash
make sim IN_DIM=64 OUT_DIM=16
```

## Notes for report
See `docs/IMPLEMENTATION_MAP.md` for a 1:1 mapping between the documentation architecture modules and this repo.
