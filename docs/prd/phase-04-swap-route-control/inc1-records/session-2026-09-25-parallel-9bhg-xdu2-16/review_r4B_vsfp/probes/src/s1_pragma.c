#include <stdlib.h>
#pragma clang section data="__DATA,__mmio" bss="__DATA,__mmiob" rodata="__TEXT,__mmior"
static volatile int K = 7;
#pragma clang section data="" bss="" rodata=""
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  if (q > 3) (void)K;
  return cq_measure(q);
}
