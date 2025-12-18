\
#include <verilated.h>
#include "Vmac_unit.h"
#include <cstdint>
#include <cstdio>

int main(int argc, char** argv){
  Verilated::commandArgs(argc, argv);
  auto* dut = new Vmac_unit;

  dut->prec = 0;
  dut->a8 = (uint8_t)(int8_t)-3;
  dut->b8 = (uint8_t)(int8_t)7;
  dut->eval();
  if((int32_t)dut->prod != -21){
    std::printf("INT8 fail: got %d\n", (int)dut->prod);
    return 2;
  }

  dut->prec = 1;
  dut->a4 = 0xD; // -3
  dut->b4 = 0x7; // 7
  dut->eval();
  if((int32_t)dut->prod != -21){
    std::printf("INT4 fail: got %d\n", (int)dut->prod);
    return 3;
  }

  dut->prec = 2;
  dut->ab = 1; dut->bb = 1; dut->eval();
  if((int32_t)dut->prod != 1) { std::printf("BIN fail1\n"); return 4; }
  dut->ab = 1; dut->bb = 0; dut->eval();
  if((int32_t)dut->prod != -1) { std::printf("BIN fail2\n"); return 5; }

  std::puts("[mac] OK");
  delete dut;
  return 0;
}
