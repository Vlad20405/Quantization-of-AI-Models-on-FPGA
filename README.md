# Quantized Dense Engine (SystemVerilog + Verilator)

A VS Code–friendly implementation of a small **quantized NN Dense layer** core:
- **INT8 / INT4 / BIN (1-bit)** modes selectable at runtime (`prec`)
- integer MAC accumulation (`int32`)
- **bias + ReLU**
- self-checking **C++ testbench** (Verilator)

This avoids HLS toolchain friction while still matching the project goal:
**quantization-aware compute on FPGA-like hardware**.

## Requirements
- Verilator (5.x recommended)
- GNU Make
- g++ / clang++

## Run
```bash
make sim
```

## Notes
- Quantization (float→int) is done in the **testbench**. Hardware consumes already-quantized tensors.
- The datapath is **sequential** (one multiply-accumulate per cycle) to be hardware-realistic.

## Top interface
The top module uses **unpacked arrays** (easy to drive in C++ with Verilator):
- `in8[IN_DIM]`, `w8[OUT_DIM][IN_DIM]`
- `in4[IN_DIM]`, `w4[OUT_DIM][IN_DIM]`
- `inb[IN_DIM]`, `wb[OUT_DIM][IN_DIM]`  where 0 => -1, 1 => +1
- `bias[OUT_DIM]`
- `out[OUT_DIM]`
