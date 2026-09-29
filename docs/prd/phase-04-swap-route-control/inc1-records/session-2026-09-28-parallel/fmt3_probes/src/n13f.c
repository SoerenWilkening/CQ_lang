#include <stdlib.h>
/* n13 flat: if (q == 20) r = cq_theta(t,.9); (the F-R1-1 shape) */
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r = 5;
  if (q == 20) r = cq_theta(t, .9);
  return cq_measure(r) + cq_measure(t); }
