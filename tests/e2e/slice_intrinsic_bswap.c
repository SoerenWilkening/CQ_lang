/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-2 / prep-b2). The golden below is a NEW
   PROGRAM's trace, not an audit substitution of the old one, and it is recorded
   as such in docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

     OLD IDIOM: (void) cq_phi(d, 0.30)  [Rz keep-alive on the dead bswap]
     NEW IDIOM: if (d > 100u) cq_phi(0.30)

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
     cq_template_bswap_i32_unc

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
   SINK and, before bd ptue (2026-10-05), turned the shape into `dead chain would
   free a measured register`; an unknown extern is declineTaintEscapes; a volatile
   local is erased by the fenv ruling's eraseDeadVolatileScalarStores). OWNER QUESTION -- see PRE_DISPOSITIONS.md.
   (PRD docs/prd/phase-04-swap-route-control/retire-swap-route-PRD.md S4.1, D1/D2.) */
/* slice_intrinsic_bswap.c — Phase 7.1 Increment E e2e link proof, Class-1
   (bijection / involution). The ONLY layer that LINKS, so the only proof that
   the curated reversible-intrinsic SIBLING symbols cq_template_bswap_i32 AND its
   void `_unc` twin cq_template_bswap_i32_unc(out, src) resolve and
   signature-match against the generated sibling ABI (cq_intrinsic_templates,
   compiled into libcq_templates.a) — Rule 2, Rule 16.

   `__builtin_bswap32` -> `@llvm.bswap.i32`, the curated Class-1 byte-reversal
   involution. Two lineages in a `noinline` helper (the boundary is LOAD-BEARING:
   whole-DAG uncompute is gated OFF in `main`):

   (A) MEASURED bswap — proves the FORWARD producer cq_template_bswap_i32.
   (B) DEAD bswap kept alive by a kickback `cq_phi` — proves the `_unc` TWIN:
       the spine reverses it via cq_template_bswap_i32_unc (recompute from the
       live source) and frees the rail, with NO `_inv`, NO added measure.

   cq_theta/cq_phi/cq_measure resolve from CQ.h (force-included by run_slice.sh). */
__attribute__((noinline))
void slice(unsigned x) {
    /* (A) measured forward bswap. */
    unsigned a = x; cq_theta(&a, 0.25);
    unsigned b = __builtin_bswap32(a);   /* llvm.bswap.i32 -> cq_template_bswap_i32 */
    (void) cq_measure(b);

    /* (B) dead bswap — proves the `_unc` twin. */
    unsigned c = x; cq_theta(&c, 0.10);
    unsigned d = __builtin_bswap32(c);   /* dead */
    if (d > 100u) cq_phi(0.30);              /* kickback keep-alive (rz_i1 on flag) */
}
int main(void) { slice(0x12345678u); return 0; }
