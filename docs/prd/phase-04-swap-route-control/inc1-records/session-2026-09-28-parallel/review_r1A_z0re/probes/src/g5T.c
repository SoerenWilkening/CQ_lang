#include <stdlib.h>
int main(int c, char **v) { int s = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .25); int x = s;
  { int r = x; if (q2 > 3) r = cq_theta(x, .2); x = cq_measure(r) + 1; }
  { int r = x; if (q2 > 3) r = cq_theta(x, .2); x = cq_measure(r) + 1; }
  { int r = x; if (q2 > 3) r = cq_theta(x, .2); x = cq_measure(r) + 1; }
  return x + cq_measure(q2); }
