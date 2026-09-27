#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q; int r;
  if (m > 3) r = m + 1; else r = 2;
  if (u == 10) cq_phi(3.14159);
  q = cq_theta(q, .7); return r + cq_measure(q); }
