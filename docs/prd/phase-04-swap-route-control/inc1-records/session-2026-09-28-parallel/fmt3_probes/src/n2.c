#include <stdlib.h>
/* fmt3: a6 with the inner branch a switch */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int q2 = cq_theta(7, .4); int r = 5;
  if (q2 > 3) { switch (t) { case 5: r = cq_theta(t, .9); break; default: r = cq_theta(5, .9); break; } }
  return cq_measure(r) + cq_measure(t) + cq_measure(q2); }
