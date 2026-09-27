#include <stdlib.h>
#pragma clang section bss="__DATA,__mmiob"
static volatile int STATUS;              /* an MMIO status register placed by the linker */
#pragma clang section bss=""
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int r = 3;
  if (q > 3) r = STATUS;                  /* a device read under quantum control */
  return cq_measure(r) + cq_measure(q);
}
