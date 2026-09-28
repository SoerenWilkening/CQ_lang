#include <stdlib.h>
/* seed classical on trip 1, the prepped register itself on later trips (loop-carried) */
int main(int c, char **v) { int s = atoi(v[1]), n = atoi(v[2]); int q2 = cq_theta(n, .25); int x = s;
  for (int i = 0; i < 3; i++) { int r = x; if (q2 > 3) r = cq_theta(x, .2); x = r; }
  return cq_measure(x) + cq_measure(q2); }
