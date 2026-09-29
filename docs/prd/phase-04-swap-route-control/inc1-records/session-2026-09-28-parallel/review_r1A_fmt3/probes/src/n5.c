#include <stdlib.h>
/* fmt3: fp member — d = (double)q, inner d == 5.0 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); double d = (double)q; int q2 = cq_theta(7, .4); double r = 5.0;
  if (q2 > 3) { if (d == 5.0) r = cq_theta(d, .9); else r = cq_theta(5.0, .9); }
  return (int)cq_measure(r) + (int)cq_measure(d) + cq_measure(q2); }
