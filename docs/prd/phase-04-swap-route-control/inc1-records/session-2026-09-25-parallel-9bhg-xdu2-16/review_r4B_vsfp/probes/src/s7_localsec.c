#include <stdlib.h>
int main(int c, char **v) {
  static volatile int K __attribute__((section("__DATA,__mmio"))) = 7;
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int r = 0;
  if (q > 3) r = K;
  return cq_measure(r) + cq_measure(q);
}
