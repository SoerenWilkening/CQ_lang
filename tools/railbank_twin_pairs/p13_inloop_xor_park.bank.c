/* Rule-13 round-2 F-1 (bd xdu2.1): q parked, then a ROLLED in-place `q ^= 3`
   loop (kickback on q > k), then the cells measured. Must DECLINE like its twin. */
#include "CQ.h"
#include <stdlib.h>
int main(int argc, char **argv) {
  int n = atoi(argv[1]); if (n <= 0) return 1;
  int q = argc; cq_theta(&q, 0.5); int b[n]; int s = 0;
  for (int i = 0; i < n; ++i) b[i] = q;                         /* park q            */
  for (int k = 0; k < n; ++k) { if (q > k) cq_phi(0.3); q ^= 3; } /* relabels q's wire */
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);            /* source: PRE-loop q */
  return s + cq_measure(q);
}
