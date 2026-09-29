#include <stdlib.h>
/* fmt3: pin through a forward function in the arm — cq_theta(t + 1) vs literal 6 */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 6;
  if (q2 > 3) { if (t == 5) r = cq_theta(t + 1, .9); else r = cq_theta(6, .9); }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
