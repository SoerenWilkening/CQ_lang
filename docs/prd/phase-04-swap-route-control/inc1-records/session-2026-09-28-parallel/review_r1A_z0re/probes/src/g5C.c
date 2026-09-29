#include <stdlib.h>
/* measurement feed-forward: the next trip's runtime seed is this trip's measured prep */
int main(int c, char **v) { int s = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .25); int x = s;
  for (int i = 0; i < 3; i++) { int r = x; if (q2 > 3) r = cq_theta(x, .2); x = cq_measure(r) + 1; }
  return x + cq_measure(q2); }
