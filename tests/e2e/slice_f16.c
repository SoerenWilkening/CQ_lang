/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-2 / prep-b2). The golden below is a NEW
   PROGRAM's trace, not an audit substitution of the old one, and it is recorded
   as such in docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

     OLD IDIOM: (void) cq_phi(d, 0.30)  [Rz keep-alive on the dead f16 add]
     NEW IDIOM: if (d == (_Float16)4.0f) cq_phi(0.30)

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
     cq_template_fadd_f16_unc

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
/* slice_f16.c — Phase 7.1 Increment D e2e smoke: the half-precision (f16) ABI.
   The ONLY layer that LINKS, so the only proof that the new frozen f16 symbols
   — cqrt_alloc_f16 / cqrt_ry_f16 / cqrt_rz_f16 / cqrt_measure_f16 and
   cq_template_fadd_f16(i32,i32) plus its void `_unc` twin
   cq_template_fadd_f16_unc(out,a,b) — all resolve and signature-match against
   the hand-written core ABI (cq_runtime) and the generated template ABI
   (cq_templates) at the `half` width (Rule 2, Rule 16). A green `opt -verify`
   and passing FileCheck on the .ll fixtures are NOT this proof.

   Two independent f16 lineages in a `__attribute__((noinline))` helper (the
   noinline boundary is LOAD-BEARING: whole-DAG uncompute is gated OFF in
   `main`, and at -O1 clang would otherwise inline `slice` so the uncompute
   never runs — same discipline as slice_compare_qq.c):

   (A) MEASURED Q+Q fadd — proves the FORWARD f16 symbol. Two f16 thetas →
       `fadd half` → `cq_template_fadd_f16(hi, hj)` → `cqrt_measure_f16`.

   (B) DEAD Q+Q fadd — proves the f16 `_unc` TWIN. Two more f16 thetas →
       `fadd half` (result dead), kept alive past -O1 DCE by a `cq_phi` (Rz)
       whose own result is dropped. The whole-DAG uncompute spine reverses the
       dead fadd ONCE via `cq_template_fadd_f16_unc(out, a, b)` (recompute-and-
       XOR from the live f16 sources) and frees each rail — NO added measure,
       NO cqrt_copy_f16 (none exists: an f16 carrier is an angle, never data).

   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
__attribute__((noinline))
void slice(_Float16 x, _Float16 y) {
    /* (A) measured Q+Q fadd — proves the forward f16 symbol. */
    _Float16 a = x; cq_theta(&a, 0.25); /* alloc f16 + ry */
    _Float16 b = y; cq_theta(&b, 0.50); /* alloc f16 + ry */
    _Float16 s = a + b;               /* fadd half QQ -> cq_template_fadd_f16 */
    (void) cq_measure(s);             /* -> cqrt_measure_f16 */

    /* (B) dead, unmeasured Q+Q fadd — proves the `_unc` twin. */
    _Float16 p = x; cq_theta(&p, 0.10); /* alloc f16 + ry */
    _Float16 q = y; cq_theta(&q, 0.20); /* alloc f16 + ry */
    _Float16 d = p + q;               /* fadd half QQ (dead) */
    if (d == (_Float16)4.0f) cq_phi(0.30);           /* Rz keep-alive; result dropped (dead) */
}
int main(void) { slice((_Float16)1.5, (_Float16)2.5); return 0; }
