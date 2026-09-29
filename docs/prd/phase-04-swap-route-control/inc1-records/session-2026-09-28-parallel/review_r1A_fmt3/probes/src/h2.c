#include <stdlib.h>
/* r1A: n9 through an EXTERN helper defined in another TU (h2.lib1.c) */
int rot(int x);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  if (t == 5) r = rot(t); else r = rot(5);
  return cq_measure(r) + cq_measure(t); }
