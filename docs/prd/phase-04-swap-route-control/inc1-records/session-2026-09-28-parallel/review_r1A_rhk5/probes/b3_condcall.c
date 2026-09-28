/* r1A probe B3: the clone CONSUMES p = 3q in a CLASSICALLY-conditional block (runtime m). */
#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int p = q * 3;
  int u = p ^ q;
  int ms = 0;
  if (m > 3) ms = cq_measure(h(m, p));
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7);
  return ms + cq_measure(q);
}
