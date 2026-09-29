#include <stdlib.h>
int g(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]);
  int q = cq_theta(m & 7, .5); int p = q * 3; int r = g(p, m); int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7);
  return cq_measure(q) + cq_measure(r);
}
