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
/* slice_uncompute_dead_shapes.c — Phase 5 (WI-7, test_C_libtooling-p2s2.7): the
   permanent LINK-COMPLETENESS guard for the `_unc` shapes that
   slice_uncompute_dead_dag does NOT exercise. WI-6 linked only the bare-QQ and
   `_hl` `_unc` forms; the `_lh`, tainted-cast, and `fneg` `_unc` symbols were
   link-PROBED ad-hoc during WI-6 and all resolved, but were never committed —
   so a name/signature drift between the generator (WI-2) and the emitter
   (WI-3/WI-4) in any of those three families would be invisible to every test
   (the ir-pass .ll fixtures assert IR text and never link; e2e is the only layer
   that LINKS — Rule 2, Rule 16). This slice closes that gap: every `_unc` shape
   the emitter can mint is now permanently link-proven by SOME golden.

   Same load-bearing scaffold as slice_uncompute_dead_dag (see its header): a
   `__attribute__((noinline))` helper (Phase-5 uncompute is gated OFF in `main`,
   and `-O1` would otherwise inline `slice` away so the uncompute never runs) and
   a `(void) cq_phi` (Rz, a side-effecting extern that READS its operand)
   keep-alive on each dead terminal so `-O1` DCE cannot drop the arithmetic while
   its result is dropped — a real `cq_template_*` terminal survives to be
   uncomputed. Each chain is a dead, unmeasured, unreturned source-derived tainted
   handle; the pass recovers the whole DAG and reverses it ONCE in reverse program
   order (LIFO), adjointing each gate via its void in-place `_unc` form (DD-3
   slots: `out` first, then the forward operands in original order), freeing each
   rail right after its last reverse-use, and undoing each Rz/Ry with a negated
   angle. NO fresh-minting `_inv`, NO added measurement (Rules 5/6), NO
   `cqrt_cswap`.

   Three independent dead lineages, one per uncovered `_unc` family:
     (A) `_lh` (literal-LEFT, handle-right; non-commutative, so the literal stays
         on the left through `-O1`): `100 - a` → `sub_i32_lh`, `5 << s` →
         `shl_i32_lh`. Exercises cq_template_sub_i32_lh_unc + shl_i32_lh_unc.
     (B) tainted widening cast: `(long) b` on an i32 handle → `sext i32 → i64`
         (the source is already the i32 theta handle by the time OpcodeLowering
         captures widths). Exercises cq_template_sext_i32_to_i64_unc.
     (C) `fneg` on a tainted float: `-fc` → `fneg float`. Exercises
         cq_template_fneg_f32_unc.

   cq_theta/cq_phi resolve from CQ.h, force-included by run_slice.sh
   (-include CQ.h -I include). */
__attribute__((noinline))
void slice(int x, int y, float z) {
    /* (A) _lh chain: literal-left sub then literal-left shl, dropped. */
    int a = cq_theta(x, 0.25);   /* taint x -> handle (alloc + ry)            */
    int s = 100 - a;             /* sub_lh  (100 literal-left, a handle)      */
    int t = 5 << s;              /* shl_lh  (5 literal-left, s shift handle)  */
    cq_phi(0.5);       /* Rz keep-alive; result dropped (dead)      */

    /* (B) tainted widening cast: i32 handle -> i64, dropped. */
    int  b  = cq_theta(y, 0.30); /* alloc + ry                                */
    long lb = (long) b;          /* sext_i32_to_i64                           */
    cq_phi(0.6);      /* Rz keep-alive (cqrt_rz_i64); dropped      */

    /* (C) fneg on a tainted float, dropped. */
    float fc = cq_theta(z, 0.40);/* alloc + ry (f32)                          */
    float fn = -fc;              /* fneg_f32                                  */
    cq_phi(0.7);      /* Rz keep-alive (cqrt_rz_f32); dropped      */
}
int main(void) { slice(2, 5, 3.0f); return 0; }
