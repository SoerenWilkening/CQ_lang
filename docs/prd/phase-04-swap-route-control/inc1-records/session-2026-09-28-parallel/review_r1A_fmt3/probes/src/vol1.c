#include <stdlib.h>
/* r1A: sel2 with a write-only non-escaping volatile local in each arm, so -O1 CANNOT fold the phi;
   the pass's own dead-cone stage (bd vsfp) deletes the stores and then mimics FoldTwoEntryPHINode +
   simplifySelectInst -- which folds select(t == s, t, s) -> s INSIDE THE PASS. */
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]);
  volatile int dummy;
  int t = cq_theta(m, .5); int s = cq_theta(n, .7); int a;
  if (t == s) { dummy = 1; a = t; } else { dummy = 2; a = s; }
  int r = cq_theta(a, .9);
  return cq_measure(r); }
