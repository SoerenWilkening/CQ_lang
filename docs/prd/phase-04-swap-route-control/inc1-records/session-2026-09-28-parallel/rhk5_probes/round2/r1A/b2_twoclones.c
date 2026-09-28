/* r1A probe B2: rail p = 3q read by TWO clone calls and a template, inside the chain window. */
#include <stdlib.h>
int h(int a, int k);
int g(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5);
  int p = q * 3;
  int u = p ^ q;
  int s = h(m, p);
  int t = g(m, p);
  int w = p + 7;
  if (u == 10) cq_phi(3.14159);
  int ms = cq_measure(s) + cq_measure(t) + cq_measure(w);
  q = cq_theta(q, .7);
  return ms + cq_measure(q);
}
