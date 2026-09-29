#include <stdlib.h>
/* r1A: the a4 shape (on-wire literal) spelled with the cq_ry STATEMENT macro in one arm */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r = q;
  if (q == 5) cq_ry(r, .9); else r = cq_theta(5, .9);
  return cq_measure(r) + cq_measure(q); }
