#include <stdlib.h>
/* nested DIAMONDS (no inner else): the inner is a6f's prep, nested in q2>3 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { if (t == 5) r = cq_theta(t, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
