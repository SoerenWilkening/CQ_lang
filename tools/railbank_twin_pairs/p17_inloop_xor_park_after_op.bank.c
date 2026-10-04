/* Rule-13 round-3 F-R3-1: the IN-PLACE op's result parked inside the relabel loop
   (`q ^= 3; b[k] = q;`). Pre-fix VIOLATION? No — the register twin ACCEPTS with a
   correct out-of-place stream, so after the fix this row is an OVER-DECLINE
   (printed, not failed). It is here so the verdict is visible and so a future
   bank-aware lowering that accepts it is byte-compared. */
#include "CQ.h"
#include <stdlib.h>
int main(int argc, char **argv) {
  int n = atoi(argv[1]); if (n <= 0) return 1;
  int q = argc; cq_theta(&q, 0.5); int s = 0;
  int b[n];
  for (int k = 0; k < n; ++k) { if (q > 5) cq_phi(0.3); q ^= 3; b[k] = q; }
  for (int i = 0; i < n; ++i) s += cq_measure(b[i]);
  return s + cq_measure(q);
}
