#include <stdlib.h>
/* r1A: sel1's twin that -O1 cannot fold: an unrelated tainted condition (t > 3) chooses t or s */
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]);
  int t = cq_theta(m, .5); int s = cq_theta(n, .7);
  int r = cq_theta((t > 3) ? t : s, .9);
  return cq_measure(r); }
