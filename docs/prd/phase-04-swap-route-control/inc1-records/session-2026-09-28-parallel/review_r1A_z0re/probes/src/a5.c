#include <stdlib.h>
/* a1 without the stale read of q afterwards */
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(7, .4); int r = s;
  if (q2 > 3) { if (q == s) r = cq_theta(q, .9); else r = cq_theta(s, .9); }
  return cq_measure(r) + cq_measure(q2); }
