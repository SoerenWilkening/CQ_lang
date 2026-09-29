#include <stdlib.h>
/* r1A: classical alternation in a loop where the arms differ only by the ANGLE sign (Trotter-style) */
int main(int c, char **v) { int n = atoi(v[2]); double th = atof(v[1]) / 100.0; int p = cq_theta(1, .2);
  for (int i = 0; i < n; i++) { if (i % 2 == 0) p = cq_theta(p, th); else p = cq_theta(p, -th); }
  return cq_measure(p); }
