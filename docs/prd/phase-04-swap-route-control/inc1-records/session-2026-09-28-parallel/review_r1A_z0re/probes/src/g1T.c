#include <stdlib.h>
/* hand-unrolled twin of g1C */
int main(int c, char **v) { int s = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .25); int acc = 0;
  { int r = cq_theta(s + 0, (q2 > 0) ? .7 : .2); acc += cq_measure(r); }
  { int r = cq_theta(s + 1, (q2 > 1) ? .7 : .2); acc += cq_measure(r); }
  { int r = cq_theta(s + 2, (q2 > 2) ? .7 : .2); acc += cq_measure(r); }
  return acc + cq_measure(q2); }
