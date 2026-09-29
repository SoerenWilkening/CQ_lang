#include <stdlib.h>
/* r1A: mflat's UNPINNED twin (t >= 5): a measurement under quantum control that no fold removes */
int main(int c, char **v) { int q = cq_theta(atoi(v[1]), .5); int t = q / 4; int m;
  if (t >= 5) m = cq_measure(t); else m = 5;
  int u = cq_theta(t, .9);
  return m + cq_measure(u); }
