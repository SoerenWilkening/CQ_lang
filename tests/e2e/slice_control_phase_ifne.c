/* 3qlq Inc 1: migrated to register-free cq_phi -- `if (q != 0) q = cq_phi(q, .25)` -> `if (q != 0) cq_phi(.25)`.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_phase_ifne.c — Phase 4 e2e smoke (issue a8c0): the idiomatic
   conditional phase whose else edge `clang -O1` const-folds to `0`.

   SOURCE INTENT:
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       if (q != 0) cq_phi(a);     // cq_phi == Rz, a PHASE on q
       measure q

   `clang -O1` reaches the else (straight-through) edge ONLY when `q == 0`, so it
   value-propagates the merge's Pred-edge incoming to the literal `0` — the merge
   is `phi [phase(q), 0]`. Pre-a8c0 the classifier declined this (its `Base ==
   Routed` gate saw the folded `0`, not the qubit). The straight-through const-fold
   re-anchor (straightThroughConstFoldHandle) proves `q == 0` on that edge from the
   `icmp eq q, 0` condition, re-anchors the routed handle to `q`, and the diamond
   lowers as a clean phase arm: flag from the tainted `icmp eq`, CSWAP q into a |0>
   rail on ¬flag (the arm fires when q != 0, the FALSE edge — the cqrt_x brackets),
   the Rz VERBATIM on the rail, CSWAP back, free the rail, strip with
   icmp_eq_inv(q). ZERO controlled gates, NO `phi i32`, NO added measure, and the
   merge RAUWs to q (not the folded 0).

   The runtime is trace-only and the diamond is flattened, so every gate fires
   unconditionally; the trace is deterministic regardless of q. cq_theta/cq_phi/
   cq_measure resolve from CQ.h, force-included by run_slice.sh. */
int slice(void) {
    int q = 3;
    q = cq_theta(q, 0.5);
    if (q != 0) cq_phi(0.25);
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
