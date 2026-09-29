#include <stdlib.h>
/* r1A: classical runtime flag (loop-invariant) choosing the angle inside a loop */
int main(int c, char **v) { int n = atoi(v[2]); int k = atoi(v[1]); int p = cq_theta(k, .2);
  for (int i = 0; i < n; i++) { if (k > 50) p = cq_theta(p, .9); else p = cq_theta(p, .3); }
  return cq_measure(p); }
