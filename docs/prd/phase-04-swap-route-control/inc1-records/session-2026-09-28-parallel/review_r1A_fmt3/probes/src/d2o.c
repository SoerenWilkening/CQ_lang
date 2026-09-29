#include <stdlib.h>
/* r1A: the pin on the OUTER edge; the inner if/else arms become identical (both cq_theta(5,.9)) */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4;
  int q2 = cq_theta(7, .4); int r = 5;
  if (t == 5) { if (q2 > 3) r = cq_theta(t, .9); else r = cq_theta(5, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
