#include <stdlib.h>
static volatile int K __attribute__((retain)) = 7;
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int r = 0;
  if (q > 3) r = K;
  return cq_measure(r) + cq_measure(q);
}
