#include <stdlib.h>
static volatile int K = 7;
int main(int c, char **v) {
  int q = cq_theta(atoi(v[1]) & 7, .5);
  int r = q;
  if (q == 5) { (void)K; r = 5; }
  r = cq_theta(r, .3);
  return cq_measure(r) + cq_measure(q);
}
