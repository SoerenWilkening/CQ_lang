/* 3qlq Inc 1: migrated to register-free cq_phi -- the classically-guarded gate loses its register.
   FLAG: the gate is CLASSICALLY controlled, so under D2 it is a global phase and is
   DELETED -- both the FIRES and the does-NOT-fire shot. The slice's whole contrast
   (one rz in the trace, not two) has nothing left to contrast. Purpose does NOT survive.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_classical_if_gate.c — test_C_libtooling-5j5 e2e smoke: the
   ONE-REGISTER classical-mux lift, the only test layer that LINKS (Rule 2,
   Rule 16). The most natural classically-controlled-gate program a user can
   write:

       int q = cq_theta(k, t);
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
    int q1 = cq_theta(3, 0.5);     /* alloc i32(3) + ry            */
    if (taken)    cq_phi(0.25);   /* rz FIRES this shot   */
    int m1 = cq_measure(q1);
    int q2 = cq_theta(4, 0.5);     /* alloc i32(4) + ry            */
    if (nottaken) cq_phi(0.75);   /* rz does NOT fire     */
    int m2 = cq_measure(q2);
    return (m1 + m2) & 0;
}
