\
#include <verilated.h>
#include "Vqnn_dense_top.h"
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <vector>
#include <algorithm>

static uint32_t rng_u32() {
  static uint32_t x = 0x12345678u;
  x ^= x << 13;
  x ^= x >> 17;
  x ^= x << 5;
  return x;
}

static float frand(float a, float b) {
  float r = (rng_u32() & 0xFFFFFF) / float(0x1000000);
  return a + (b - a) * r;
}

static int clamp(int v, int lo, int hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

static float calibrate_absmax(const std::vector<float>& v, float qmax) {
  float m = 0.0f;
  for (float x: v) m = std::max(m, std::fabs(x));
  if (m < 1e-12f) m = 1e-12f;
  return m / qmax;
}

static int8_t quant_int8(float x, float scale) {
  int q = (int)llround((double)(x / scale));
  q = clamp(q, -128, 127);
  return (int8_t)q;
}

static int8_t quant_int4(float x, float scale) {
  int q = (int)llround((double)(x / scale));
  q = clamp(q, -8, 7);
  return (int8_t)q;
}

static uint8_t quant_bin(float x) {
  return (x < 0.0f) ? 0u : 1u; // 0 => -1, 1 => +1
}

static void tick(Vqnn_dense_top* dut, vluint64_t& t) {
  dut->clk = 0; dut->eval(); t++;
  dut->clk = 1; dut->eval(); t++;
}

static int32_t u32_to_s32(uint32_t u) {
  return (int32_t)u;
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);
  auto* dut = new Vqnn_dense_top;

  vluint64_t t = 0;
  dut->rst_n = 0;
  dut->start = 0;
  dut->prec  = 0;

  for (int i = 0; i < 5; i++) tick(dut, t);
  dut->rst_n = 1;

  // Random float tensors
  std::vector<float> x(IN_DIM);
  std::vector<float> w(OUT_DIM * IN_DIM);
  std::vector<int32_t> bias(OUT_DIM);

  for (int i = 0; i < IN_DIM; i++) x[i] = frand(-1.0f, 1.0f);
  for (int o = 0; o < OUT_DIM; o++) {
    bias[o] = (int32_t)llround(frand(-50.0f, 50.0f));
    for (int i = 0; i < IN_DIM; i++) w[o*IN_DIM + i] = frand(-1.0f, 1.0f);
  }

  auto run_mode = [&](int prec_mode, const char* name) {
    float qmax = (prec_mode == 0) ? 127.0f : (prec_mode == 1 ? 7.0f : 1.0f);

    float sx = calibrate_absmax(x, qmax);

    std::vector<int8_t> x8(IN_DIM), x4(IN_DIM);
    std::vector<uint8_t> xb(IN_DIM);
    for (int i = 0; i < IN_DIM; i++) {
      x8[i] = quant_int8(x[i], sx);
      x4[i] = quant_int4(x[i], sx);
      xb[i] = quant_bin(x[i]);
    }

    std::vector<int8_t> w8(OUT_DIM*IN_DIM), w4(OUT_DIM*IN_DIM);
    std::vector<uint8_t> wb(OUT_DIM*IN_DIM);

    for (int o = 0; o < OUT_DIM; o++) {
      std::vector<float> row(IN_DIM);
      for (int i = 0; i < IN_DIM; i++) row[i] = w[o*IN_DIM + i];
      float sw = calibrate_absmax(row, qmax);

      for (int i = 0; i < IN_DIM; i++) {
        w8[o*IN_DIM + i] = quant_int8(w[o*IN_DIM + i], sw);
        w4[o*IN_DIM + i] = quant_int4(w[o*IN_DIM + i], sw);
        wb[o*IN_DIM + i] = quant_bin(w[o*IN_DIM + i]);
      }
    }

    // Drive inputs
    for (int i = 0; i < IN_DIM; i++) {
      dut->in8[i] = (uint8_t)x8[i];
      dut->in4[i] = (uint8_t)(x4[i] & 0xF);
      dut->inb[i] = (uint8_t)(xb[i] & 1u);
    }

    for (int o = 0; o < OUT_DIM; o++) {
      dut->bias[o] = (uint32_t)bias[o];
      for (int i = 0; i < IN_DIM; i++) {
        dut->w8[o][i] = (uint8_t)w8[o*IN_DIM + i];
        dut->w4[o][i] = (uint8_t)(w4[o*IN_DIM + i] & 0xF);
        dut->wb[o][i] = (uint8_t)(wb[o*IN_DIM + i] & 1u);
      }
    }

    dut->prec = (uint8_t)prec_mode;

    // Start pulse
    dut->start = 1;
    tick(dut, t);
    dut->start = 0;

    // Wait done
    int guard = 0;
    while (!dut->done) {
      tick(dut, t);
      if (++guard > (OUT_DIM*IN_DIM + OUT_DIM + 50)) {
        std::printf("ERROR: timeout waiting done\n");
        std::exit(2);
      }
    }

    // Integer reference
    std::vector<int32_t> ref(OUT_DIM, 0);
    for (int o = 0; o < OUT_DIM; o++) {
      int32_t acc = 0;
      for (int i = 0; i < IN_DIM; i++) {
        int32_t prod = 0;
        if (prec_mode == 0) prod = (int32_t)x8[i] * (int32_t)w8[o*IN_DIM + i];
        else if (prec_mode == 1) prod = (int32_t)x4[i] * (int32_t)w4[o*IN_DIM + i];
        else prod = (xb[i] == wb[o*IN_DIM + i]) ? 1 : -1;
        acc += prod;
      }
      acc += bias[o];
      if (acc < 0) acc = 0;
      ref[o] = acc;
    }

    // Compare
    int mism = 0;
    for (int o = 0; o < OUT_DIM; o++) {
      int32_t y = u32_to_s32(dut->out[o]);
      if (y != ref[o]) mism++;
    }

    std::printf("[%s] mismatches: %d / %d\n", name, mism, OUT_DIM);
    if (mism) {
      for (int o = 0; o < std::min(5, OUT_DIM); o++) {
        int32_t y = u32_to_s32(dut->out[o]);
        std::printf("  o=%d  dut=%d  ref=%d\n", o, (int)y, (int)ref[o]);
      }
      std::exit(3);
    }
  };

  run_mode(0, "INT8");
  run_mode(1, "INT4");
  run_mode(2, "BIN");

  std::puts("All modes OK.");
  delete dut;
  return 0;
}
