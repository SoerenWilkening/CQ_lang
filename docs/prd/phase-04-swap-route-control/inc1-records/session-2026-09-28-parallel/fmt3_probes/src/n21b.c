#include <stdlib.h>
/* n21 without the stale read of t: the in-place controlled Ry arm on t */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r = t;
  if (q == 20) r = cq_theta(t, .9);
  return cq_measure(r) + cq_measure(q); }
