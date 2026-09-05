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
/* slice_ctlz_idiom_loop.c — bd ww4c Increment 1, the e2e link+trace proof for
   the shift-count loop -> `llvm.ctlz` recognizer (CtlzIdiomPrepass.cpp).

   DELIBERATELY SYNTHETIC. The two REAL cells (`ilogb.f64`, `ilogbf.f32`, vendored
   from openlibm) are Increment 2 and are not touched here. What this slice buys
   is what no lit fixture can: the substituted four-op chain has to LINK (Rule 2 —
   the only layer that proves every emitted symbol resolves and signature-matches,
   including all four void `_unc` twins), it has to RUN, and it has to pass stage
   2b's Rule-6 free-pairing STRICT — the only gate that speaks for rail identities
   at all, since no trace label can say whether a rail was `|0>` when freed.

   THE SOURCE IS openlibm's SPELLING, NOT LLVM's, and that is the point. bd ww4c's
   decisive experiment measured that `for (…; hx > 0; hx <<= 1)` produces NO
   `llvm.ctlz` at -O1, -O2 or -O3, while LLVM's own `while (x != 0)` produces one
   at all three — stock `LoopIdiomRecognize` fires on the second and never on the
   first. Re-measured here at the ship floor: stage 1 contains zero `ctlz`. So a
   `cq_template_ctlz_i32` in this trace can only have come from CQ's recognizer.

   WHY THE MASKS. `(w & 0x000ffffe) | 1` pins the entry value to [1, 2^20) — which
   is exactly what `s_ilogb.c` knows at that point (`hx != 0` from the dominating
   branch, `hx < 2^20` from the subnormal test), and it makes clang FOLD the source
   guard, reproducing PRD §3.1's measured shape: unconditional loop entry with the
   pre-shift sitting in the PREHEADER. Two of the three target loops look like this,
   and the masks are how a synthetic slice gets there honestly rather than by
   deleting the guard by hand.

   A guarded single loop is deliberately NOT modelled here — see
   ir-pass/test/lowering_ctlz_idiom_guarded_no_preshift.ll for why (the enclosing
   2-incoming const-fallthrough diamond is a PRE-EXISTING PredMux gap, W7 clause
   (e), unrelated to this pass), and lowering_ctlz_idiom_both_loops.ll for the
   guarded loop in its real `s_ilogb.c` nesting, where it does lower completely.

   HOW TO READ THE GOLDEN against the closed form
   f(v) = 1 + (ctlz(v<<1) & (N-1)),  c_exit = (C0-1) - (ctlz(v<<1) & (N-1)):

     cq_template_shl_i32_hl(., 11)    the PREHEADER pre-shift — untouched. The
                                      recognizer takes the recurrence's entry
                                      value as OPAQUE and never looks through it
                                      (PRD §5.4); folding it into the constant is
                                      the hazard, not a missed optimisation
     cq_template_shl_i32_hl(., 1)     v << 1
     cq_template_ctlz_i32(.)          ctlz, emitted with the `i1 false` immarg
     cq_template_and_i32_hl(., 31)    & (N-1), N from the recurrence's own TYPE
     cq_template_sub_i32_lh(-1023, .) (C0-1) - m, with C0 = -1022

   NO loop, NO flag mint, NO controlled copy, NO select anywhere in the trace. The
   `sgt 0` idiom's zero-repair is the MASK, not the select LLVM's canonical
   `x != 0` lowering needs — that is the design's cost argument (4 tainted ops per
   loop, not the ~10 the decision memo budgeted), and this golden is where it stops
   being an argument and becomes a measurement.

   (B) is the uncompute side: its counter feeds only a `cq_phi` keep-alive whose
   result is dropped, so the whole substituted chain is dead and the Phase-5
   whole-DAG LIFO spine reverses it — the golden shows all four `_unc` twins firing
   in reverse program order, each before its rail is freed. Every one of those
   symbols already exists in libcq_templates.a: ZERO new frozen symbols, no YAML
   edit, no regeneration (Rule 15 untouched).

   cq_theta/cq_phi/cq_measure resolve from CQ.h (force-included by run_slice.sh). */

/* (A) the idiom with a preheader pre-shift, MEASURED — the forward chain. */
__attribute__((noinline))
int scan_measured(unsigned u) {
    unsigned w  = cq_theta(u, 0.25);
    unsigned hx = (w & 0x000ffffeu) | 1u;      /* 1 <= hx < 2^20, as s_ilogb knows */
    int ix = -1022;
    for (hx <<= 11; (int) hx > 0; hx <<= 1)    /* hx<<11 is positive: guard folds */
        ix--;
    return cq_measure(ix);
}

/* (B) the idiom with NO pre-shift and a different seed, DEAD and kept alive by a
   cq_phi — the four `_unc` twins and the LIFO reversal. */
__attribute__((noinline))
void scan_uncomputed(unsigned u) {
    unsigned w  = cq_theta(u, 0.10);
    unsigned lx = (w & 0x7ffffffeu) | 1u;      /* 1 <= lx < 2^31: provably positive */
    int ix = -1043;
    for (; (int) lx > 0; lx <<= 1)
        ix--;
    cq_phi(0.30);                   /* Rz keep-alive; result dropped */
}

int main(void) {
    (void) scan_measured(0x00000123u);
    scan_uncomputed(0x00000001u);
    return 0;
}
