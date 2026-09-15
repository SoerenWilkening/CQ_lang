/* f10 — RE-ATTACK on the fix (Rule 13: a fix introduces new holes).  A `_Bool`
   bank whose per-cell theta is CHAINED on a LOOP-INVARIANT rail: every trip is
   an in-place Ry on ONE wire, so all three cells park the SAME handle after
   three rotations.  The register twin is the bd `3d8q` sibling shape.  This is
   the shape the memory hop CANNOT see on its own — the staling gate is the
   reader's own previous dynamic instance, not a sibling on the seed's wire. */
#include "CQ.h"
int slice(void) {
  bool q = 0;
  q = cq_theta(q, 0.3);
  bool b0[3]; int s = 0;
  for (int i = 0; i < 3; ++i) b0[i] = cq_theta(q, 0.5);
  for (int i = 0; i < 3; ++i) s += cq_measure(b0[i]);
  return s + (int) cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
