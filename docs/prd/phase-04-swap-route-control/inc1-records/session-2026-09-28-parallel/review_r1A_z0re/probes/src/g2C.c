#include <stdlib.h>
/* runtime base = loop-carried CLASSICAL value, angle select in the exit block; trailing Ry on the condition register */
int main(int c, char **v) { int s = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .25); int t = s;
  for (int i = 0; i < n; i++) t = t * 2 + 1;
  int r = cq_theta(t, (q2 > 3) ? .7 : .2); q2 = cq_theta(q2, .6);
  return cq_measure(r) + cq_measure(q2); }
