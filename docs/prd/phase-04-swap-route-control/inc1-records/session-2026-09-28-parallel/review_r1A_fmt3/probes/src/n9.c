#include <stdlib.h>
/* fmt3 class: a6's inner if/else with NO outer region -> -O1 erases the branch entirely */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  if (t == 5) r = cq_theta(t, .9); else r = cq_theta(5, .9);
  return cq_measure(r) + cq_measure(t); }
