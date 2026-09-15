/* f08 — the `_Bool`-CELL spelling of the P1, written so the rail is genuinely a
   `_Bool` (the review's `f03` declined at `unknown callee` because its
   `cq_theta(seed, …)` took an `int` and was assigned to a `bool`, so it never
   reached the fence).  This is the STORAGE-CAST half of the memory hop: the
   cell is `i8`, the rail `i1`, so the reader names the `trunc` and the store
   parks a `zext`.  A hop that did not strip BOTH casts would miss it. */
#include "CQ.h"
int slice(void) {
  bool q = 0;
  q = cq_theta(q, 0.5);
  bool b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = q;
  q = cq_theta(q, 0.7);                     /* NON-DIAGONAL, relabels the wire */
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + (int) cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
