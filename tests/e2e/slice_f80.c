/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-2 / prep-b2). The golden below is a NEW
   PROGRAM's trace, not an audit substitution of the old one, and it is recorded
   as such in docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

     OLD IDIOM: (void) cq_phi(d, 0.30)  [Rz keep-alive on the dead f80 add]
     NEW IDIOM: if (d == 4.0L) cq_phi(0.30)

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
     cq_template_fadd_f80_unc

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
/* slice_f80.c — bd 3c6m.4 e2e smoke: the long-double (f80 / x86_fp80) ABI, the
   width behind the 54 `…l` math.h variants. The ONLY layer that LINKS, so the
   only proof that the new frozen f80 symbols — cqrt_alloc_f80 / cqrt_ry_f80 /
   cqrt_measure_f80 and cq_template_fadd_f80 (+ its `_unc` twin)
   and the intrinsic-backed cq_template_sqrt_f80 (+ `_unc`) — all resolve and
   signature-match the hand-written core ABI (cq_runtime) and the generated
   template ABI (cq_templates / cq_intrinsic_templates) at the long-double width
   (Rule 2, Rule 16). A green `opt -verify` and passing .ll FileCheck are NOT
   this proof.

   On this x86-64 host `long double` IS x86_fp80, so CQ.h's _Generic dispatches
   the `long double` token to the f80 suffix (__LDBL_MANT_DIG__ == 64).

   Three f80 lineages in a `__attribute__((noinline))` helper (the noinline
   boundary is LOAD-BEARING: whole-DAG uncompute is gated OFF in `main`, and at
   -O1 clang would otherwise inline `slice` so the uncompute never runs — same
   discipline as slice_f16.c):

   (A) MEASURED sqrtl over a Q+Q fadd — proves the FORWARD f80 symbols. Two f80
       thetas → `fadd x86_fp80` → `sqrtl` (@llvm.sqrt.f80 → cq_template_sqrt_f80)
       → `cqrt_measure_f80`. This is the headline `…l` shape.

   (B) DEAD Q+Q fadd — proves the fadd_f80 `_unc` TWIN. Two more f80 thetas →
       `fadd x86_fp80` (result dead), kept alive past -O1 DCE by the `d == 4` flag
       of a kickback `cq_phi`. The whole-DAG uncompute spine reverses the
       dead fadd via `cq_template_fadd_f80_unc(out, a, b)` and frees each rail —
       NO cqrt_copy_f80 (an f80 carrier is an angle, never data).

   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
#include <math.h>

__attribute__((noinline))
void slice(long double x, long double y) {
    /* (A) measured sqrtl over a Q+Q fadd — proves the forward f80 symbols. */
    long double a = x; cq_theta(&a, 0.25); /* alloc f80 + ry */
    long double b = y; cq_theta(&b, 0.50); /* alloc f80 + ry */
    long double s = a + b;               /* fadd x86_fp80 QQ -> cq_template_fadd_f80 */
    long double r = sqrtl(s);            /* @llvm.sqrt.f80 -> cq_template_sqrt_f80 */
    (void) cq_measure(r);                /* -> cqrt_measure_f80 */

    /* (B) dead, unmeasured Q+Q fadd — proves the fadd_f80 `_unc` twin. */
    long double p = x; cq_theta(&p, 0.10); /* alloc f80 + ry */
    long double q = y; cq_theta(&q, 0.20); /* alloc f80 + ry */
    long double d = p + q;               /* fadd x86_fp80 QQ (dead) */
    if (d == 4.0L) cq_phi(0.30);              /* kickback keep-alive (rz_i1 on flag) */
}
int main(void) { slice(1.5L, 2.5L); return 0; }
