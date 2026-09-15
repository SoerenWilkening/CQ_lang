/* p2_uncond_store_no_read.c — Track A, session 2026-09-15, bd `de8n`.
   THE POSITIVE CONTROL for p1: identical but the store is UNCONDITIONAL, so both
   C7 conjuncts hold and the verdict is `Bank` with the promoter not firing (B8 —
   there is no in-loop read to forward). It is the shape the deferred type rewrite
   MAY have without the promoter ever touching it. */
#include <stdbool.h>
int slice(int n) {
  bool z = 0;
  bool b[3] = {0};
  for (int i = 0; i < 3; ++i) { b[i] = cq_theta(z, 0.5); }
  int s = 0;
  for (int i = 0; i < 3; ++i) s += cq_measure(b[i]);
  return s + n;
}
int main(void) { return slice(2); }
