/* F-1 with the relabel loop conditioned on a DIFFERENT register r. */
#include "CQ.h"
#include <stdlib.h>
int main(int argc, char **argv) {
  int n = atoi(argv[1]); if (n <= 0) return 1;
  int q = argc; cq_theta(&q, 0.5); int b[n]; int s = 0; int r = argc+1; cq_theta(&r, .2);
  for (int i = 0; i < n; ++i) b[i] = q;
  for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q ^= 3; }
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q) + cq_measure(r);
}
