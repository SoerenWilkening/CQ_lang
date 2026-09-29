#include <stdlib.h>
/* r1A: n9 through a NOINLINE same-TU helper (the helper has no nomerge) */
__attribute__((noinline)) static int rot(int x) { return cq_theta(x, .9); }
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  if (t == 5) r = rot(t); else r = rot(5);
  return cq_measure(r) + cq_measure(t); }
