#include <stdlib.h>
/* r1A: CLASSICAL runtime choice of a literal STATE PREP seed-angle pair (if/else of two fresh preps) */
int main(int c, char **v) { int k = atoi(v[2]); int r;
  if (k > 3) r = cq_theta(5, .9); else r = cq_theta(6, .3);
  return cq_measure(r); }
