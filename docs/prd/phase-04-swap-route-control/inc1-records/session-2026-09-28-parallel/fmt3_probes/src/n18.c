#include <stdlib.h>
/* the Ry-stem angle select (shipped accept shape) — the nomerge cost probe */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int p = cq_theta(3, .2);
  if (q > 3) p = cq_theta(p, .9); else p = cq_theta(p, .3);
  return cq_measure(p) + cq_measure(q); }
