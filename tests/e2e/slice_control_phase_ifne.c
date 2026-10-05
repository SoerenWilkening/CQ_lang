/* 3qlq Inc 1: migrated to register-free cq_phi -- `if (q != 0) q = cq_phi(q, .25)` -> `if (q != 0) cq_phi(.25)`.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_phase_ifne.c — Phase 4 e2e smoke (issue a8c0): the idiomatic
   conditional phase whose else edge `clang -O1` const-folds to `0`.

   SOURCE INTENT:
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       if (q != 0) cq_phi(a);     // cq_phi == Rz, a PHASE on q
       measure q

   Pre-3qlq (register form) `clang -O1` folded the merge's straight-through
   incoming to the literal `0` (`phi [phase(q), 0]`); pre-a8c0 the classifier
   declined that, and a8c0's straight-through const-fold re-anchor
   (straightThroughConstFoldHandle) accepted it. Register-free, the arm writes no
   value, so `-O1` emits no merge `phi`: `br (icmp eq q, 0)` with the cq_phi on
   the FALSE edge. The diamond lowers as a clean phase arm by kickback: the flag
   h1 = icmp_eq(q, 0) is minted into a fresh |0> ancilla, the Rz fires
   UNCONTROLLED on ¬h1 (cqrt_rz_i1 between two cqrt_x, since the arm fires when
   q != 0), the compare `_unc` strips h1 back to |0>, and ONE cqrt_free releases
   it. ZERO controlled gates, NO cswap, NO `phi i32`, NO added measure; the
   user's measure reads q.

   The runtime is trace-only and the diamond is flattened, so every gate fires
   unconditionally; the trace is deterministic regardless of q. cq_theta/cq_phi/
   cq_measure resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);
    if (q != 0) cq_phi(0.25);
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
