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
/* slice_fp80_union_unc.c — bd szpr (3c6m.51 Inc-3 Rule-13 critic Gap 1): the
   i80 field-insert WRITE-surface `_unc` adjoints, TRACE-VERIFIED. Every prior
   fp80-union cell is `cq_measure(fn(q))`, so FreePoint classifies the terminal
   Measured and the whole-DAG uncompute correctly SKIPS — the Inc-2 `_unc`
   twins (zext/shl/or/and i80, bitcast i80<->f80) were symbol-existent and
   link-verified but had never PRODUCED a trace line. This slice makes them
   fire through the shipped Phase-5 dead-DAG mechanism (the slice_f80.c case-B
   discipline): a promoted fp80-union RMW on a DEDICATED theta rail whose
   packed result feeds a result-dropped `cq_phi` (Rz keep-alive past -O1 DCE)
   — a dead source-derived lineage the whole-DAG LIFO uncompute must reverse.

   The `__attribute__((noinline))` boundary is LOAD-BEARING (slice_f16/f80
   discipline): whole-DAG uncompute is gated OFF in `main`; at -O1 clang would
   inline `slice` and the dead DAG would ride main's gate (the retained
   standalone `slice` would carry the `_unc` calls but never run).

   ANALYTIC AUDIT OF RECORD (the szpr deliverable; adjoints are Bennett
   out-of-place recompute-and-XOR, EmitInverse.cpp): the golden's reverse
   stream is the EXACT reverse program order of the 13-op forward chain
   bitcast f80->i80 / lshr / trunc / zext / add / and+and / or (the i64
   expsign rebuild) / and-keep / zext / shl / or (the i80 repack) / bitcast
   i80->f80. The Rz keep-alive unwinds FIRST (Rz(-0.25), diag-adjoint), then
   each `_unc(out, args...)` recomputes f(args) and XORs onto `out` returning
   that rail to |0> IMMEDIATELY before its `cqrt_free` (Rule 6: every free is
   a proven-|0> rail); every `args` handle is still allocated when its `_unc`
   fires (frees strictly follow last use, LIFO); the dedicated theta rail
   itself unwinds last (cqrt_ry(-0.5) — the fully-dead lineage returns the
   source to |0>) and frees. The MEASURED rails h0/h1 are left allocated
   (Measured — the measurement owns them). The `and_i80_hl(h3, -1)` label is
   the documented 64-bit trace-label truncation of the i80 low-64 keep mask
   0xFFFFFFFFFFFFFFFF (the symbol stream is exact; Inc-3 accepted limitation).

   Phase-6 route NOT buildable today (measured, 2026-07-16, recorded on bd
   szpr): a specialized callee cannot carry the union — an fp80 quantum
   arg/return declines at the spec fp gate ("no reversible copy"), and an
   int-signature callee with the union inside declines at the spec body gate
   ("non-reversibilizable construct") because promoteFp80Union's fpSeedValueOk
   requires a TAINTED seed and the pre-specialization original is untainted —
   the promotion fixpoint runs before specialization. The synthesized void
   uncompute twin path itself is already trace-verified by the spec goldens
   (cq_template_mul_i32_unc in spec_chained_ctl); the i80-specific adjoints
   are what Gap 1 flagged, verified here. */

union IEEEl2bits {
    long double e;
    struct {
        unsigned int manl : 32;
        unsigned int manh : 32;
        unsigned int exp  : 15;
        unsigned int sign : 1;
        unsigned int junkl : 16;
        unsigned int junkh : 32;
    } bits;
};

__attribute__((noinline))
long double slice(void) {
    /* (A) measured business — anchors the trace; its rails stay allocated. */
    long double x = cq_theta(0.5L, 0.5);
    long double r = x + 1.0L;
    long double m = cq_measure(r);

    /* (B) dead fp80-union RMW on a dedicated rail: extract exp, +2,
       field-insert back (the scalbnl idiom), kept alive past -O1 DCE by a
       result-dropped cq_phi. The whole-DAG uncompute reverses it — the i80
       write-surface `_unc` family fires. */
    long double q = cq_theta(0.25L, 0.5);
    union IEEEl2bits u;
    u.e = q;
    u.bits.exp = u.bits.exp + 2;
    cq_phi(0.25);
    return m;
}

int main(void) { (void) slice(); return 0; }
