/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-2 / prep-b2). The golden below is a NEW
   PROGRAM's trace, not an audit substitution of the old one, and it is recorded
   as such in docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

     OLD IDIOM: (void) cq_phi(t, 0.5)  [Rz keep-alive on the iteration-local xor]
     NEW IDIOM: if (t == 11) cq_phi(0.5)

   WHY. Under owner decision D1 `cq_phi` takes no register, so the documented
   "Rz keep-alive" — the opaque READER that stopped `clang -O1` deleting the dead
   tainted lineage this slice exists to exercise — no longer reads anything, and
   the whole lineage is DCE'd at STAGE 1 (prep-b PROBE 2, measured: the migrated
   `slice_intrinsic_bswap` lost its `llvm.bswap.i32` outright). Nothing else in
   `CQ.h` reads a quantum value without being a sink or a non-diagonal gate
   (PRE_DISPOSITIONS.md §5 OQ-1 checks all four candidates).

   The replacement consumer is a KICKBACK UNDER A DERIVED CONDITION, which is the
   honest CQ consumer for a dead chain: it exercises the forward chain, the flag
   mint, `cqrt_rz_i1`, the compare `_unc` strip, the chain's OWN `_unc` reversal
   and the frees — i.e. it keeps exactly the coverage this slice was written for.
   RECOVERED AND MEASURED IN THE GOLDEN BELOW:
     cq_template_icmp_eq_i32_hl_unc per activation (the iteration-local discharge)

   ⚠ THE CONDITION'S SHAPE IS LOAD-BEARING, NOT DECORATION. A plain equality
   against a constant is folded THROUGH the very op under test whenever that op
   is invertible — MEASURED: `bswap(c) == K` becomes `c == bswap(K)` and the
   bswap disappears; `clz(c) == 12` becomes a range test on `c`; `sext(b) == K`
   becomes `b == K`; `-fc == K` becomes `fc == -K`; `(a<<2)^9 == 9` becomes a
   mask test. Where that happened the condition was changed to one the folder
   cannot invert — an ORDERED compare, or a Q+Q op against a second tainted
   register whose operands are both non-constant — and the recovered `_unc`
   symbol above is the witness that it worked. */
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
   in-body discharge (compare `_unc` + `cqrt_free`) resolves and runs ONCE PER
   ITERATION over a rail re-allocated each trip (Rule 2/16).

   Each iteration mints a FRESH quantum rail `q` (born in body), derives
   `t = q ^ 9` and applies a kickback `cq_phi` under `t == 11`; neither is
   measured, escaped or loop-carried. MEASURED at -O1: clang folds `t == 11`
   through the xor to `icmp eq q, 2`, so NO xor survives and the per-trip flag is
   the only iteration-local ancilla (the pre-3qlq xor `_unc` recovery is gone).
   Each trip mints the flag, fires `cqrt_rz_i1` on it, strips it with its
   compare `_unc` and frees it IN-BODY, before the backedge.

   The golden (n = 3 fixed so the trace is deterministic) shows THREE
   alloc/ry/mint/rz_i1/strip/free groups over DISTINCT handle pairs (h0/h1,
   h2/h3, h4/h5 — monotonic, proving a fresh alloc each iteration, never a reuse)
   with THREE frees (each iteration's flag). A function-scope free would run
   once over the K-times-reallocated rail (use-after-free + (K-1) double-frees,
   the central Rule-13 hazard, §2.5/Risk 1) — the per-iteration handle
   progression IS the proof that did not happen. `noinline` is load-bearing
   (whole-DAG uncompute is gated OFF in `main`, and -O1 would otherwise inline
   `slice` away so the uncompute never runs). cq_theta/cq_phi resolve from
   CQ.h, force-included by run_slice.sh. */
__attribute__((noinline))
void slice(int x, int n) {
    for (int i = 0; i < n; i++) {
        int q = x; cq_theta(&q, 0.25); /* fresh rail, born in body            */
        int t = q ^ 9;               /* -O1 folds t == 11 to q == 2: no xor */
        if (t == 11) cq_phi(0.5);       /* kickback keep-alive (rz_i1 on flag) */
    }
}
int main(void) { slice(2, 3); return 0; }
