#include <stdlib.h>
/* one theta claimed by two regions? diamond prep whose arm theta has a quantum angle select */
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(7, .4); int r = s;
  if (q2 > 3) r = cq_theta(s, q > 1 ? .7 : .2);
  return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
