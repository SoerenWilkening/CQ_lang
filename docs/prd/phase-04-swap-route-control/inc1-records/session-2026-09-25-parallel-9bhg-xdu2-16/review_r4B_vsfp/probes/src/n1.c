#include <stdlib.h>
static volatile int K = 7;
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  _Bool c2 = q < 6;
  if (q > 3) { (void)K; if (c2) (void)K; }
  return cq_measure(q) + cq_measure(c2);
}
