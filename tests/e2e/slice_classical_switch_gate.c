/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, finding F-B2-3 / prep-b2, orchestrator remedy).
   The golden below is a NEW PROGRAM's trace, not an audit substitution, and it is
   recorded as such in GOLDEN_REGEN.md §12.

     OLD: case 1: cq_phi(0.25);   case 2: cq_phi(0.50); cq_phi(0.55);   ...
     NEW: case 1: q1 = cq_theta(q1,.25);  case 2: q1 = cq_theta(q1,.50);
                                          q1 = cq_theta(q1,.55);       ...

   WHY — identical to `slice_classical_if_gate`'s (read it there in full). All
   SEVEN gates were classically controlled, so D2 deleted every one of them:
   MEASURED before this rewrite, the golden went from 2 `cqrt_rz` lines to ZERO and
   became BYTE-IDENTICAL to `slice_classical_if_gate`'s — two `alloc/ry/measure`
   triples, with no arm, no default and no multi-gate arm distinguishable in it.
   `cq_theta` restores every one of those distinctions: it is in place, so the
   N-ary merge phi is still a pure renaming for the one-register lift, the classical
   `switch` is still left byte-untouched, and the 2-GATE ARM is again visible as two
   gates in the trace. What changed is the gate's spelling, not the property. */
/* slice_classical_switch_gate.c — test_C_libtooling-sbt1.3 e2e smoke: the
   N-ARY (N>2) one-register classical-mux lift (Phase 7.1 Increment C), the
   only test layer that LINKS (Rule 2, Rule 16). The natural classical N-way
   `switch` around an in-place quantum gate on ONE register:

       int q = cq_theta(k, t);
       switch (classical_sel) {          // classical N-way dispatch
         case 1:  cq_phi(a);                  break;   // 1 gate
         case 2:  cq_phi(b); cq_phi(c); break;  // 2-gate chain
         case 3:  cq_phi(d);                  break;   // 1 gate
         default:                                    break;   // 0 gates
       }
       cq_measure(q);

   DISTINCT per-case gate chains (1 / 2 / 1 / 0 gates) keep clang -O1 from
   merging the cases into one angle-selected block, so the construct survives as
   a real `switch` with a single FOUR-incoming merge phi whose incomings are
   distinct SSA names of the SAME register (cq_phi is in place — RotationLowering
   emits cqrt_rz on q's handle AT THE CALL'S POSITION inside the case block and
   RAUWs the result to q). The N-ary lift
   (TaintPropagation::liftOneRegisterMergePhi, generalized in Increment C) proves
   the phi a pure renaming — every edge's chain lives in its own case block AND
   no arm gate can reach the merge through ANY OTHER edge whose record omits it
   (the generalized (7a) over all j != i) — RAUWs it to the wire base, erases it,
   and leaves the CLASSICAL switch byte-untouched. So each emitted cqrt_rz stays
   INSIDE its case block and fires iff that case ran THIS SHOT.

   The scrutinee derives from argc (`sel = (argc + 1) % 4` is 2 on every real
   no-arg invocation — argc == 1 is just the program name), so -O1 cannot
   constant-fold the switch away; the golden pins case 2's TWO-gate chain (both
   cqrt_rz fire, in source order, on the one handle), with case 1's and case 3's
   single rz NOT firing. Goldening the multi-gate case is deliberate: it
   exercises the N-ary lift's single-block-chain proof (condition (6)) for a
   REAL chain, not just a lone gate. A second register q2 with `sel2 = argc + 7`
   (= 8, an absent case → the DEFAULT arm) goldens the default-only path: no
   case rz fires.

   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh
   (-include CQ.h -I include). */
int main(int argc, char **argv) {
    (void) argv;

    /* (argc + 1) % 4 == 2 on every real (no-arg) invocation — case 2 (argc is 1,
       the program name). The modulo keeps the value small and the switch
       genuinely classical + un-foldable. */
    int sel = (argc + 1) % 4;
    int q1 = cq_theta(3, 0.5);          /* alloc i32(3) + ry */
    switch (sel) {
        case 1: q1 = cq_theta(q1, 0.25); break;                       /* no fire   */
        case 2: q1 = cq_theta(q1, 0.50); q1 = cq_theta(q1, 0.55); break;/* BOTH FIRE */
        case 3: q1 = cq_theta(q1, 0.60); break;                       /* no fire   */
        default: break;                                             /* no fire   */
    }
    int m1 = cq_measure(q1);

    /* argc + 7 == 8 on every real invocation -> an absent case -> the DEFAULT
       arm: no case rz fires. */
    int sel2 = argc + 7;
    int q2 = cq_theta(4, 0.5);          /* alloc i32(4) + ry */
    switch (sel2) {
        case 2: q2 = cq_theta(q2, 0.75); break;                       /* no fire   */
        case 3: q2 = cq_theta(q2, 0.90); q2 = cq_theta(q2, 0.95); break;/* no fire   */
        default: break;                                             /* default   */
    }
    int m2 = cq_measure(q2);

    return (m1 + m2) & 0;
}
