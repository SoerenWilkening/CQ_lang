/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-2 / prep-b2). The golden below is a NEW
   PROGRAM's trace, not an audit substitution of the old one, and it is recorded
   as such in docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

     OLD IDIOM: (void) cq_phi(zc, 0.30)  [Rz keep-alive on the dead u40 lineage]
     NEW IDIOM: if (zc == (u40)5) cq_phi(0.30)

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
     cq_template_and_i64_hl_unc  (the i40 mask twin)

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
/* slice_bitint.c — Phase 7.1 follow-up D5 (test_C_libtooling-m0yi) e2e link
   proof: a non-power-of-2 _BitInt(N) INTERMEDIATE round-trips with NO new ABI.

   FINDING (real clang 19.1.7 -O1, contra the plan's R-D assumption that clang
   emits a raw `add i40`): `unsigned _BitInt(40)` arithmetic rounds up to the i64
   storage width and emits the i40 wraparound as a stock high-bit mask
   `and i64 ..., 0xFFFFFFFFFF` (= 2^40-1) — both ops already have frozen templates
   (cq_template_add_i64 / cq_template_and_i64_hl), so the proposed
   cq_template_mask_<W> frozen family is unnecessary.

   This is the ONLY layer that LINKS, so the only proof that the round+mask gate
   stream AND the mask's void _unc twin (cq_template_and_i64_hl_unc) resolve and
   signature-match the generated ABI (Rule 2, Rule 16). Two lineages:

   (A) MEASURED unsigned _BitInt(40) add — proves the forward round+mask producers.
   (B) DEAD masked value kept alive by a cq_phi — proves the and-mask _unc twin
       (recompute-and-XOR from the live source) + the |0> free.

   cq_theta/cq_phi/cq_measure resolve from CQ.h (force-included by run_slice.sh). */
typedef unsigned _BitInt(40) u40;

__attribute__((noinline))
void slice(unsigned long x, unsigned long y) {
    /* (A) measured forward: (u40)a + (u40)b, then mask back to 40 bits. */
    unsigned long a = x; cq_theta(&a, 0.25);
    unsigned long b = y; cq_theta(&b, 0.50);
    u40 za = (u40)a;
    u40 zb = (u40)b;
    u40 zs = za + zb;                    /* i40 add — clang masks at 2^40 */
    (void) cq_measure((unsigned long)zs);

    /* (B) dead mask — proves the and-mask _unc + recompute-from-live-source. */
    unsigned long c = x; cq_theta(&c, 0.10);
    u40 zc = (u40)c;                     /* and i64 c, 2^40-1 — dead */
    if (zc == (u40)5) cq_phi(0.30);   /* Rz keep-alive; result dropped */
}
int main(void) { slice(0xFFFFFFFFFFul, 1ul); return 0; }
