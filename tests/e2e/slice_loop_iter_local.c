/* 3qlq Inc 1: migrated to register-free cq_phi -- `(void) cq_phi(<dead value>, th)` -> `cq_phi(th)`.
   FLAG (KEEP-ALIVE SITE -- MEASURED, and this is the migration's headline cost):
   `(void) cq_phi(<dead>, th)` was a keep-alive. Rz is a side-effecting extern that
   READS ITS OPERAND, which is the only reason `-O1` DCE could not drop the dead
   arithmetic this slice exists to exercise. A register-free `cq_phi(th)` reads
   NOTHING, so the dead lineage is deleted AT STAGE 1, before the pass runs -- the
   loss is not one trace line, it is the whole chain and the `_unc` symbol the slice
   was written to LINK. Measured on slice_intrinsic_bswap: the `llvm.bswap.i32` is
   absent from stage-1 IR. There is no drop-in replacement in CQ.h (cq_measure is a
   SINK and turns the shape into `dead chain would free a measured register`; an
   unknown extern is declineTaintEscapes; a volatile local is erased by the fenv
   ruling's eraseDeadVolatileScalarStores). OWNER QUESTION -- see PRE_DISPOSITIONS.md.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_loop_iter_local.c — Phase 7.3 Inc 2 (799w.2): the per-iteration in-body
   uncompute Case B e2e golden — the only layer that LINKS, so the only proof the
   in-body whole-DAG reversal (xor `_unc` + `cqrt_free`) resolves and runs ONCE
   PER ITERATION over a rail re-allocated each trip (Rule 2/16).

   Each iteration mints a FRESH quantum rail `q` (born in body), derives an
   iteration-local temp `t = q ^ 9`, keeps it alive with a dead `(void) cq_phi`
   (so -O1 DCE cannot drop the arithmetic), and drops both — neither measured nor
   escaped, neither loop-carried. `lowerLoops` recognizes the iteration-local loop
   and marks its body; the Phase-5 spine lifts its two backedge guards for the
   proven iteration-local DAG and places the recovery + free IN-BODY, after the
   keep-alive Rz and before the backedge.

   The golden (n = 3 fixed so the trace is deterministic) shows exactly THREE
   balanced compute/uncompute pairs over DISTINCT handle pairs (h0/h1, h2/h3,
   h4/h5 — monotonic, proving a fresh alloc each iteration, never a reuse) with
   SIX frees (two per iteration). A function-scope free would run once over the
   K-times-reallocated rail (use-after-free + (K-1) double-frees, the central
   Rule-13 hazard, §2.5/Risk 1) — the per-iteration handle progression IS the
   proof that did not happen. `noinline` is load-bearing (whole-DAG uncompute is
   gated OFF in `main`, and -O1 would otherwise inline `slice` away so the
   uncompute never runs). cq_theta/cq_phi resolve from CQ.h, force-included by
   run_slice.sh. */
__attribute__((noinline))
void slice(int x, int n) {
    for (int i = 0; i < n; i++) {
        int q = cq_theta(x, 0.25);   /* fresh rail, born in body            */
        int t = q ^ 9;               /* iteration-local temp (xor_hl)       */
        cq_phi(0.5);       /* Rz keep-alive; result dead -> dies  */
    }
}
int main(void) { slice(2, 3); return 0; }
