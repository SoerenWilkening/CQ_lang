#include <stdlib.h>
/* the zt0b RELATIONAL fold on an ARG-0 SELECT (not a theta merge) feeding a ternary angle
   select: `(q == s) ? q : s` folds to `s` at -O1. Unlike the theta-merge fold (fmt3), the
   source here has NO in-place rotation of q: the select's value is s on every branch, so
   the folded module denotes the same unitary. nomerge has nothing to block. */
int main(int c, char **v) { int m = atoi(v[1]), s = atoi(v[2]); int q = cq_theta(m, .5); int q2 = cq_theta(7, .4);
  int r = cq_theta((q == s) ? q : s, (q2 > 3) ? .75 : .25);
  return cq_measure(r) + cq_measure(q) + cq_measure(q2); }
