#include <stdlib.h>
/* zt0b (select(q==s,q,s)->s) INSIDE a diamond prep region: source rotates q in place on q2>3 && q==s */
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(7, .4); int r = s;
  if (q2 > 3) { if (q == s) r = cq_theta(q, .9); else r = cq_theta(s, .9); }
  return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
