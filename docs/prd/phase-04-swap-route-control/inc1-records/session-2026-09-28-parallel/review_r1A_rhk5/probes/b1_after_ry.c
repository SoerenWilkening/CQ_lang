/* r1A probe B1: the clone CONSUMES p = 3q AFTER a non-diagonal gate on q. */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int p = q * 3;
  q = cq_theta(q, .7);
  int s = h(m, p);
  int ms = cq_measure(s);
  return ms + cq_measure(q);
}
