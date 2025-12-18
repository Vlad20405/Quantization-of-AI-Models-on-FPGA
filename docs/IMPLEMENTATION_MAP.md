# Implementation ↔ Documentation Map

This document maps the **implementation modules** to the architecture modules proposed in the documentation.

## 1) Quantizer Unit
- **Doc**: "Unitatea de cuantizare (Quantizer Unit)" — rounding + clipping, FP32→INTx, INT8/INT4/BIN definitions.
- **Impl**: `rtl/quantizer_unit.sv`
  - Implements **rounding + saturation** to INT8 and INT4.
  - Implements **binarization** (sign-based) for BIN.
  - Hardware interface uses **fixed-point input** (`in_fx`) + **shift scale** (`shift`), which is a typical FPGA-friendly way to implement the same quantization behavior.

## 2) Integer MAC blocks / MAC Arrays
- **Doc**: "MAC Arrays" — int8×int8, int4×int4, and binary XNOR-style.
- **Impl**:
  - `rtl/mac_unit.sv` — the primitive MAC product (per element)
  - `rtl/mac_array.sv` — optional spatial parallelism (NUM_PE)

## 3) Dense Engine (Fully Connected)
- **Doc**: "Engine pentru straturi Dense" — multiply and accumulate on 16/32 bits.
- **Impl**: `rtl/dense_engine.sv`
  - Sequential accumulation by default (NUM_PE=1)
  - Keeps accumulation in **int32**, as described.

## 4) Activation (ReLU)
- **Doc**: "Blocul de activare" — `relu_q(x)=max(0,x)`.
- **Impl**: `rtl/activation_relu.sv`

## 5) Mixed Precision Controller
- **Doc**: "Unitate pentru precizie configurabila (Mixed Precision Controller)"
- **Impl**: `rtl/mixed_precision_ctrl.sv`
  - Selects the active precision per layer/run.

## 6) Memory Banks (BRAM Buffers / Weight Banks)
- **Doc**: "Memory Banks" (BRAM/URAM/Distributed RAM)
- **Impl**: `rtl/memory_bank.sv` (behavioral BRAM-like)
  - In the Verilator flow we still pass tensors from TB for simplicity, but the module is provided for FPGA mapping.

## 7) Scheduler and Control Unit
- **Doc**: "Scheduler si Control Unit" — orchestrates layer order/precision/buffers.
- **Impl**: `rtl/scheduler_ctrl.sv`
  - Drives the dense engine and asserts `done` deterministically.

## 8) Conv2D Engine
- **Doc**: "Engine Conv2D" (line buffers / sliding windows).
- **Impl**: Not implemented in this baseline; provided as a **stub** for extension: `rtl/conv2d_stub.sv`
  - Documented extension points included.

> The baseline is intentionally focused on a complete, verified INT8/INT4/BIN Dense path (core requirement),
> while keeping the Conv2D module as a clearly defined next step.
