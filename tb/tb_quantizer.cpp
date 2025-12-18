\
#include <verilated.h>
#include "Vquantizer_unit.h"
#include <cstdint>
#include <cstdio>

static int32_t sat(int32_t v, int32_t lo, int32_t hi){
  if(v<lo) return lo; if(v>hi) return hi; return v;
}

int main(int argc, char** argv){
  Verilated::commandArgs(argc, argv);
  auto* dut = new Vquantizer_unit;

  struct TV { int32_t in; int shift; };
  TV t[] = { {0,2}, {1000,2}, {-1000,2}, {100000,4}, {-100000,4}, {127,0}, {-128,0} };

  for (auto &v : t) {
  dut->in_fx = v.in;
  dut->shift = v.shift;
  dut->eval();

  // DUT outputs
  int32_t dq8 = (int8_t)(dut->q8 & 0xFF);

  int32_t dq4 = (int8_t)(dut->q4 & 0xF);   // sign extend 4-bit
  if (dq4 & 0x8) dq4 |= ~0xF;

  // Hardware input is IN_W=16 -> truncation to int16_t
  int32_t in_hw = (int16_t)v.in;

  // Reference: rounding then shift (computed on what HW actually receives)
  int32_t r = in_hw;
  if (v.shift > 0) {
    int32_t add = 1 << (v.shift - 1);
    r = (in_hw >= 0) ? (in_hw + add) : (in_hw - add);
    r = r >> v.shift;
  }

  int32_t rq8 = sat(r, -128, 127);
  int32_t rq4 = sat(r, -8, 7);

  if (dq8 != rq8 || dq4 != rq4) {
    std::printf(
      "Mismatch in=%d hw=%d shift=%d dq8=%d rq8=%d dq4=%d rq4=%d\n",
      v.in, in_hw, v.shift, dq8, rq8, dq4, rq4
    );
    return 2;
  }
}

std::puts("[quantizer] OK");
delete dut;
return 0;

}
