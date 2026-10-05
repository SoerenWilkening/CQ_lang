/* 3qlq Inc 1: migrated to register-free cq_phi -- `q = cq_phi(q, th)` -> `cq_phi(th)` at every site (branch phase by kickback).
   FLAG (PRD S6.3): the tainted arm now holds 2 cq_phi calls, which the Inc-1
   decline partition refuses ("an arm with N>1 cq_phi calls"). Expected
   post-increment class is a DECLINE, not an accept -- an owner call, not this
   migration's: the kickback needs no angle sum (two rz_i1 on the SAME flag are
   exact), so the N>1 refusal is a scoping choice, not a physics one.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_control_switch_eqfold.c — Phase 4.5 e2e smoke (WI-6,
   test_C_libtooling-bkpz.6): the equality-guarded `br` diamond, written as the
   regression FLOOR for the additive D1–D7 `tryEqFoldArm` clause on the
   pre-3qlq register form (see below). Today it links the kickback PHASE-diamond
   stream on an `icmp eq` flag and proves every symbol resolves against
   libcq_runtime (Rule 2, Rule 16). control_swap_eqfold_diamond.ll is the
   eq-fold IR contract; the §4D detection-only path added no new emit code and
   no new ABI symbol.

   SOURCE INTENT (an EQUALITY-guarded multi-gate PHASE arm — the §4D ACCEPT shape):
       q : tainted quantum handle (cq_theta == Ry, the sole taint source)
       if (q == 7) { cq_phi(.25); cq_phi(.75); }   // PHASE arm
       measure q

   Pre-3qlq (register form) clang -O1 KNEW q == 7 inside the arm and CONST-FOLDED
   the first gate's arg-0 handle to the literal (`cq_phi(i32 7, θ)`), so the
   phase spine bottomed at `ConstantInt 7` and the inequality classifier would
   have declined `control flow`; tryEqFoldArm re-recognized it as a pure PHASE
   arm over the icmp's tainted operand (D1 equality predicate · D2 folded const
   base · D3 the icmp's non-const operand IS the routed handle · D4 literal ==
   folded const · D5 routed operand tainted · D6 pure spine · D7 classical
   angles). Register-free, `cq_phi(double)` has no data operand, so -O1 has
   nothing to fold: the arm is two `cq_phi(double)` calls under
   `br (icmp eq q, 7)`, with no merge `phi`.

   The diamond lowers by kickback: the flag h1 = icmp_eq(q, 7) is minted into a
   fresh |0> ancilla, both arm Rz gates fire VERBATIM and UNCONTROLLED on it as
   cqrt_rz_i1, the compare `_unc` strips it back to |0>, and ONE cqrt_free
   releases it (a clean reset). q is measured.

   TWO gates deliberately (pre-3qlq, a single-gate arm canonicalized at -O1 into
   a tainted ANGLE select); both Rz land on the SAME flag. EXACTLY ONE free (the
   flag) — freeing q would be a hidden measurement (Rule 6). ZERO controlled
   gates, no cswap, no `phi i32`. The runtime is trace-only and the diamond is
   flattened, so every emitted gate fires unconditionally; cqrt_measure
   returns 0. The golden pins the trace captured from REAL linked output
   (templates BEFORE runtime — load-bearing link order). cq_theta/cq_phi/
   cq_measure resolve from CQ.h. */
int slice(void) {
    int q = 3;
    cq_theta(&q, 0.5);             /* taint q -> handle (alloc, ry)             */
    if (q == 7) {                  /* tainted icmp eq -> kickback phase arm      */
        cq_phi(0.25);       /* arm gate 1 (Rz) — cqrt_rz_i1 on the flag   */
        cq_phi(0.75);       /* arm gate 2 (Rz) — cqrt_rz_i1 on the flag   */
    }
    return cq_measure(q);
}
int main(void) { (void) slice(); return 0; }
