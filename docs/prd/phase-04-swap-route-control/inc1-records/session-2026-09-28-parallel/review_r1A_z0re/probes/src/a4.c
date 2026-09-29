#include <stdlib.h>
/* LITERAL twin of a1: inner if/else rotates q in place under q==5 inside a region on q2>3 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (q == 5) r = cq_theta(q, .9); else r = cq_theta(5, .9); }
  return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
