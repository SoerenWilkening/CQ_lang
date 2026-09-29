#include <stdlib.h>
/* r1A: n9 through a noinline helper -- the UNMERGED twin: only ONE arm calls the helper
   (hand-written twin of the helper form without a fold opportunity) */
__attribute__((noinline)) static int rot(int x) { return cq_theta(x, .9); }
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int t = q / 4; int r;
  r = rot(t);
  return cq_measure(r) + cq_measure(t); }
