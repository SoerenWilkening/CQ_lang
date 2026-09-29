#include <stdlib.h>
/* n24's HAND-UNROLLED twin at K = 3 (the trip count the probe runner passes as argv[2]) */
int main(int c, char **v) { int r = cq_theta(3, .2); int acc = 0;
  { int q = cq_theta(0, .5); if (q > 3) r = cq_theta(r, .9); else r = cq_theta(r, .3); acc += cq_measure(q); }
  { int q = cq_theta(1, .5); if (q > 3) r = cq_theta(r, .9); else r = cq_theta(r, .3); acc += cq_measure(q); }
  { int q = cq_theta(2, .5); if (q > 3) r = cq_theta(r, .9); else r = cq_theta(r, .3); acc += cq_measure(q); }
  return acc + cq_measure(r); }
