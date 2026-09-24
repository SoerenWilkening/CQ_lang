/* the ARRAY-FREE twin of p14. */
#include "CQ.h"
#include <stdlib.h>
int main(int argc, char **argv) {
  int n = atoi(argv[1]); if (n <= 0) return 1;
  int q = cq_theta(argc, 0.5); int c = q; int s = 0; int r = cq_theta(argc+1, .2);

  for (int k = 0; k < n; ++k) { if (r > k) cq_phi(0.3); q ^= 3; }
  for (int i = 0; i < n; ++i) s += cq_measure(c);
  return s + cq_measure(q) + cq_measure(r);
}
