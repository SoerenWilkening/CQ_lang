#include <stdlib.h>
/* r1A: TERNARY on arg-0 over TWO QUANTUM registers. CQ reads (t == s) ? t : s as a 4.4 mux into a
   FRESH rail; InstSimplify folds select(t==s, t, s) -> s, so -O1 hands the pass cq_theta(s, .9):
   an IN-PLACE rotation of s. Header-independent (no merge involved). */
int main(int c, char **v) { int m = atoi(v[1]); int n = atoi(v[2]);
  int t = cq_theta(m, .5); int s = cq_theta(n, .7);
  int r = cq_theta((t == s) ? t : s, .9);
  return cq_measure(r); }
