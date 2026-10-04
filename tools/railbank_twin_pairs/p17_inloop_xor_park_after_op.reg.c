/* the hand-unrolled n=3 twin of p17. */
#include "CQ.h"
#include <stdlib.h>
int main(int argc, char **argv) {
  int n = atoi(argv[1]); if (n <= 0) return 1;
  int q = argc; cq_theta(&q, 0.5); int s = 0;
  if (q > 5) cq_phi(0.3); q ^= 3; int c0 = q;
  if (q > 5) cq_phi(0.3); q ^= 3; int c1 = q;
  if (q > 5) cq_phi(0.3); q ^= 3; int c2 = q;
  s = cq_measure(c0) + cq_measure(c1) + cq_measure(c2);
  return s + cq_measure(q);
}
