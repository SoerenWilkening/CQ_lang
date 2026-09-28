#include <stdlib.h>
/* the legitimate program r1A's a1.c folds to at -O1 */
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(7, .4); int r = s;
  if (q2 > 3) r = cq_theta(s, .9);
  return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
