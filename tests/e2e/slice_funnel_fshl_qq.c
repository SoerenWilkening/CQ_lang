/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-2 / prep-b2). The golden below is a NEW
   PROGRAM's trace, not an audit substitution of the old one, and it is recorded
   as such in docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

     OLD IDIOM: (void) cq_phi(dead, 0.6)  [Rz keep-alive on the dead funnel shift]
     NEW IDIOM: if (dead == 0u) cq_phi(0.6)

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
     cq_template_fshl_i32_qql_unc

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
/* slice_funnel_fshl_qq.c — bd 20xt.1 e2e link-layer smoke (Rule 2 / Rule 16) for
   the general constant-amount funnel shift fshl(a,b,n) with a!=b + BOTH data
   operands quantum handles. This is the ONLY layer that LINKS and proves the new
   frozen symbols cq_template_fshl_i32_qql[_unc] RESOLVE and SIGNATURE-MATCH — the
   lit fixtures cover the lowering, but not the link (the exact gap the Rule-13
   adversarial review flagged; it also confirmed both symbols resolve via a manual
   link+run, which this commits as a regression baseline).

   Two funnels, each with LINEAR (no-fan-out) sources so the whole-DAG uncompute
   engages (Rule 8):
     - r = (a<<16)|(b>>16)  -> fshl.i32(a,b,16), MEASURED  -> the FORWARD qql only.
     - dead = (c<<8)|(d>>24) -> fshl.i32(c,d,8), guards a kickback cq_phi, then
       dead -> reverse-play: the void cq_template_fshl_i32_qql_unc(out,c,d,8)
       recompute-and-XOR from the still-LIVE c,d,8 zeroes the rail, which is then
       freed (Rule 6), then the flag; c,d are NOT ry-reversed or freed (the golden
       frees h4 and h5 only). Every freed rail is freed at |0> (0 double-frees).

   `slice` is __attribute__((noinline)) so the trace deterministically reflects the
   slice() lowering (main's discarded-result inline copy drops the dead-funnel
   uncompute — a pre-existing terminal-selection behavior when the measured result
   is dead; noinline pins the canonical forward+_unc shape). */
#include <stdint.h>

__attribute__((noinline))
unsigned int slice(void) {
    unsigned int a = 7u; cq_theta(&a, 0.5);
    unsigned int b = 9u; cq_theta(&b, 0.25);
    unsigned int r = (a << 16) | (b >> 16);      /* fshl(a,b,16) -> qql, measured */
    unsigned int c = 3u; cq_theta(&c, 0.375);
    unsigned int d = 5u; cq_theta(&d, 0.125);
    unsigned int dead = (c << 8) | (d >> 24);    /* fshl(c,d,8) -> qql, dead */
    if (dead == 0u) cq_phi(0.6);                    /* kickback keep-alive -> reverse-play _unc */
    return cq_measure(r);
}

int main(void) {
    (void) slice();
    return 0;
}
