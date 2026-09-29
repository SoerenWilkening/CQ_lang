#include <stdlib.h>
/* r1A: classical first-iteration special case inside a loop (if (i == 0) ... else ...) */
int main(int c, char **v) { int n = atoi(v[2]); int p = cq_theta(atoi(v[1]), .2);
  for (int i = 0; i < n; i++) { if (i == 0) p = cq_theta(p, .9); else p = cq_theta(p, .3); }
  return cq_measure(p); }
