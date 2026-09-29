#include <stdlib.h>
/* Round 2: can the zt0b relational fold produce a RUNTIME-BASE ANGLE SELECT?
   Both outer arms hold the same inner if/else (q == s) differing only in the angle. */
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(7, .4); int r;
  if (q2 > 3) { if (q == s) r = cq_theta(q, .9); else r = cq_theta(s, .9); }
  else        { if (q == s) r = cq_theta(q, .3); else r = cq_theta(s, .3); }
  return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
