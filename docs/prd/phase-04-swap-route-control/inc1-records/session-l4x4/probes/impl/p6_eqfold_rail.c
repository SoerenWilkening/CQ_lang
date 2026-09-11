/* p6 — ⚠ HEADER CORRECTED BY THE ROUND-1 RULE-13 REVIEW (finding F-4). THIS
   PROBE IS NOT AN EQ-FOLD AND NEVER WAS.

   The original header read: "an equality-folded arm under a rail condition (the
   EQ-FOLD class)."  There is no equality anywhere in the source and no eq-fold
   anywhere in the output. `if (b) cq_phi(0.7);` on a bare `_Bool` is the bd
   `3qlq.4` (Inc 1b) BRANCH-PHASE KICKBACK, shipped before this increment, and it
   ACCEPTS on this tree and on `main` 0c7380c alike — MEASURED, the emitted
   stream contains `cqrt_rz_i1` and no data merge at all.

   `tryEqFoldArm`'s subject is an `if (q == K)` DIAMOND that `clang -O1`
   const-folds on the equality edge (D1-D7); it is reached through an `ICmpInst`
   condition, so a BARE RAIL cannot present it — which is exactly why §2.6 lists
   the EQ-FOLD row as "unreachable from C".

   SO IT MEASURES NOTHING ABOUT §2.6's EQ-FOLD ROW, and `IMPL_l4x4b.md` §1 must
   not cite it for that row; the row is fenced by `declineRailClass()` at the
   eq-fold accept site (read, not measured) and has NO DEDICATED FIXTURE, which
   §1 now says outright.

   KEPT RATHER THAN DELETED because it is a real regression probe for the
   SEPARATION this increment relies on: a `cq_phi` arm on a rail must keep going
   to the Inc-1b kickback and must NOT be captured by the new rotation-arm path.
   Its accept, and the `cqrt_rz_i1` in its stream, are that statement. */
int slice(void) {
    _Bool b = 0;
    int r = 7;
    b = cq_theta(b, 0.5);
    r = cq_theta(r, 0.25);
    if (b) { cq_phi(0.7); }
    return (int) cq_measure(b) + cq_measure(r);
}
int main(void) { (void) slice(); return 0; }
