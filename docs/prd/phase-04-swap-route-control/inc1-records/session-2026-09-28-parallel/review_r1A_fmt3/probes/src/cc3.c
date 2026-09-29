#include <stdlib.h>
/* r1A: classical alternation of the Ry angle inside a classically-bounded loop */
int main(int c, char **v) { int n = atoi(v[2]); int p = cq_theta(atoi(v[1]), .2);
  for (int i = 0; i < n; i++) { if (i & 1) p = cq_theta(p, .9); else p = cq_theta(p, .3); }
  return cq_measure(p); }
