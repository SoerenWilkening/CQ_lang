/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, finding F-B2-3 / prep-b2, orchestrator remedy).
   The golden below is a NEW PROGRAM's trace, not an audit substitution of the old
   one, and it is recorded as such in
   docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md §12.

     OLD: if (taken) cq_phi(0.25);        / if (nottaken) cq_phi(0.75);
     NEW: if (taken) cq_theta(&q1,.25); / if (nottaken) cq_theta(&q2,.75);

   WHY. This slice's whole subject is the CONTRAST — one classically-guarded gate
   FIRES this shot and one does NOT — and under owner decision D2 a
   classically-controlled `cq_phi` is a GLOBAL PHASE and is DELETED, so BOTH shots
   lost their gate. MEASURED before this rewrite: the golden went from 1 `cqrt_rz`
   to ZERO and read `alloc; ry; measure` twice, i.e. it had nothing left to
   contrast and was byte-identical to `slice_classical_switch_gate`'s golden. A
   test that still compiles and no longer exercises its own subject is the bd
   `3c6m.63` / `165/174` failure mode, and it is invisible to a green suite.

   `cq_theta` is the replacement gate and nothing else about the slice moves. It is
   the right one for THIS property, not a convenience: like the retired register
   `cq_phi` it is an IN-PLACE gate whose lowered result RAUWs to its argument's i32
   handle, so the two incomings of the merge phi are still distinct SSA names for
   the SAME register and `TaintPropagation::liftOneRegisterMergePhi` — the thing
   this slice links — is exercised exactly as before. The CLASSICAL branch is still
   left byte-untouched, no flag is minted, no routing and no controlled gate is
   emitted, and the trace still shows the gate for q1 and NO gate for q2. What
   changed is the gate's spelling (`cqrt_ry_i32` where the golden used to say
   `cqrt_rz_i32`), not the property. */
/* slice_classical_if_gate.c — test_C_libtooling-5j5 e2e smoke: the
   ONE-REGISTER classical-mux lift, the only test layer that LINKS (Rule 2,
   Rule 16). The most natural classically-controlled-gate program a user can
   write:

       int q = k; cq_theta(&q, t);
       if (classical_c) cq_phi(a);    // classical if around a gate
       cq_measure(q);

   survives clang -O1 as a branch + merge phi whose two incomings are distinct
   SSA names for the SAME register (cq_phi is in place). The lift
   (TaintPropagation::liftOneRegisterMergePhi) proves the phi a pure renaming,
   RAUWs it to the wire base, erases it, and leaves the CLASSICAL branch
   byte-untouched — so the emitted cqrt_rz stays INSIDE the arm and fires iff
   the condition held THIS SHOT. That per-shot trace difference is the
   user-written classical control over WHICH gates execute — fine classically
   (no superposed condition, no flag, no routing, no controlled gates).

   Both polarities are goldened in one run: `taken` (argc > 0) is true on
   every run with no args, `nottaken` (argc > 100) is false — so the trace
   must show the rz for q1 and NO rz for q2. Conditions derive from argc so
   -O1 cannot constant-fold the branches away.

   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by
   run_slice.sh (-include CQ.h -I include). */
int main(int argc, char **argv) {
    (void) argv;
    int taken    = argc > 0;       /* 1 on every real invocation */
    int nottaken = argc > 100;     /* 0 on every real invocation */
    int q1 = 3; cq_theta(&q1, 0.5); /* alloc i32(3) + ry            */
    if (taken)    cq_theta(&q1, 0.25);       /* gate FIRES this shot   */
    int m1 = cq_measure(q1);
    int q2 = 4; cq_theta(&q2, 0.5); /* alloc i32(4) + ry            */
    if (nottaken) cq_theta(&q2, 0.75);       /* gate does NOT fire     */
    int m2 = cq_measure(q2);
    return (m1 + m2) & 0;
}
