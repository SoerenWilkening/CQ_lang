#include <stdlib.h>
static volatile int K __attribute__((section("__DATA,__mmio"))) = 7;
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  q = q + K;
  return cq_measure(q);
}
