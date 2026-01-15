#include <verilated.h>
#include "Vqnn_fpga_wrapper.h"
#include <cstdio>
#include <cstdint>

static void tick(Vqnn_fpga_wrapper* dut) {
  dut->clk = 0; dut->eval();
  dut->clk = 1; dut->eval();
}

int main(int argc, char** argv) {
  Verilated::commandArgs(argc, argv);

  auto* dut = new Vqnn_fpga_wrapper;

  uint64_t cycles = 0;

  // reset
  dut->rst_n = 0;
  dut->start = 0;
  for (int i = 0; i < 5; i++) { tick(dut); cycles++; }

  dut->rst_n = 1;
  for (int i = 0; i < 2; i++) { tick(dut); cycles++; }

  // start pulse (1 cycle)
  uint64_t start_cycle = cycles;
  dut->start = 1;
  tick(dut); cycles++;
  dut->start = 0;

  // wait done
  const uint64_t TIMEOUT = 1000000;
  while (!dut->done) {
    tick(dut); cycles++;
    if (cycles - start_cycle > TIMEOUT) {
      std::printf("ERROR: timeout waiting done\n");
      return 2;
    }
  }

  uint64_t cycles_per_inference = cycles - start_cycle;
  std::printf("cycles_per_inference=%llu\n",
              (unsigned long long)cycles_per_inference);

  delete dut;
  return 0;
}
