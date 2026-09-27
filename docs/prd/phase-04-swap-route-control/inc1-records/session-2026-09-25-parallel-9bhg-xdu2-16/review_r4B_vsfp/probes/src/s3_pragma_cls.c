#include <stdlib.h>
#pragma clang section data="__DATA,__mmio"
static volatile int K = 7;
#pragma clang section data=""
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  q = q + K;
  return cq_measure(q);
}
