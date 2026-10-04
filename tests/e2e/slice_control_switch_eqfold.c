/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, th)` -> `cq_phi(th)` at every site (branch phase by kickback).
   FLAG (PRD S6.3): the tainted arm now holds 2 cq_phi calls, which the Inc-1
   decline partition refuses ("an arm with N>1 cq_phi calls"). Expected
   post-increment class is a DECLINE, not an accept -- an owner call, not this
   migration's: the kickback needs no angle sum (two rz_i1 on the SAME flag are
   exact), so the N>1 refusal is a scoping choice, not a physics one.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_switch_eqfold.c — Phase 4.5 e2e smoke (WI-6,
   test_C_libtooling-bkpz.6): the equality-folded `br` diamond, the regression
   FLOOR for emitRegion-reuse — it re-tests the golden 4.1 PHASE-diamond path
   end-to-end through the additive D1–D7 `tryEqFoldArm` clause, proving the
   re-anchored eq-fold emits the identical routed stream and every symbol resolves
   against libcq_runtime (Rule 2, Rule 16). control_swap_eqfold_diamond.ll is the
   pinned IR contract; the §4D detection-only path reuses emitRegion VERBATIM (no
   new emit code, no new ABI symbol).

   SOURCE INTENT (an EQUALITY-guarded multi-gate PHASE arm — the §4D ACCEPT shape):
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       if (q == 7) { cq_phi(.25); cq_phi(.75); }   // PHASE arm
       measure q

   clang -O1 KNOWS q == 7 inside the arm, so it CONST-FOLDS the first gate's arg-0
   handle to the literal: the arm gate is `cq_phi(i32 7, θ)`, not `cq_phi(i32 q,
   θ)`. The phase spine then bottoms at `ConstantInt 7` instead of the routed
   handle, so the inequality classifier would decline `control flow`. tryEqFoldArm
   re-recognizes it as a pure PHASE arm over the icmp's tainted operand (D1
   equality predicate · D2 folded const base · D3 the icmp's non-const operand IS
   the routed handle · D4 literal == folded const · D5 routed operand tainted · D6
   pure spine · D7 classical angles) and re-anchors the routed handle, so the
   diamond lowers through emitRegion VERBATIM: flag from the tainted `icmp eq` ->
   CSWAP q into a |0> rail -> the arm Rz gates VERBATIM/UNCONTROLLED on the rail
   (re-anchor BY PHYSICS — only arg-1/the angle is read, the folded arg-0 const is
   discarded; a surviving folded cq_phi would RAUW to its const and degenerate the
   merge into a wrong data-mux) -> CSWAP back -> free the |0> rail (Rz|0>=|0>, a
   clean reset) -> strip the boolean with icmp_eq_inv(q) -> free the flag. q (NOT
   the phi) is measured; RAUW merge->q.

   TWO gates deliberately: a single-gate arm canonicalizes at -O1 into a tainted
   ANGLE select (4.4-deferred — declines), so the multi-gate arm is what keeps the
   real br-diamond. EXACTLY TWO frees (work rail + flag) — a third would be a
   hidden measurement (Rule 6). ZERO controlled gates, no surviving folded
   `cq_phi`, no `phi i32`. The runtime is trace-only and the diamond is flattened,
   so every emitted gate fires unconditionally; cqrt_measure returns 0. The golden
   pins the trace captured from REAL linked output (templates BEFORE runtime —
   load-bearing link order). cq_theta/cq_phi/cq_measure resolve from CQ.h. */
int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);             /* taint q -> handle (alloc, ry)             */
    if (q == 7) {                  /* eq-folded br diamond -> emitRegion (§4D)   */
        cq_phi(0.25);       /* arm gate 1 (Rz) — arg-0 folds to 7         */
        cq_phi(0.75);       /* arm gate 2 (Rz) — VERBATIM on the rail     */
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
