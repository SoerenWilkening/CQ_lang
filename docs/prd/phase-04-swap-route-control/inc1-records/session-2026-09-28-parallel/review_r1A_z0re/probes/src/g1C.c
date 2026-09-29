#include <stdlib.h>
/* in-loop Ry-stem angle select on a RUNTIME base (rolled) */
int main(int c, char **v) { int s = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .25); int acc = 0;
  for (int i = 0; i < 3; i++) { int r = cq_theta(s + i, (q2 > i) ? .7 : .2); acc += cq_measure(r); }
  return acc + cq_measure(q2); }
