#include <stdlib.h>
/* n17 with NO outer region */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int W = q + 1; int r;
  if (q == 5) r = cq_theta(W, .9); else r = cq_theta(6, .9);
  return cq_measure(r) + cq_measure(W) + cq_measure(q); }
