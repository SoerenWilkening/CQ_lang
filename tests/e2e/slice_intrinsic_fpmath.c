/* ⚠ REWRITTEN PROGRAM (3qlq Inc 1, OQ-2 / prep-b2). The golden below is a NEW
   PROGRAM's trace, not an audit substitution of the old one, and it is recorded
   as such in docs/prd/phase-04-swap-route-control/inc1-records/GOLDEN_REGEN.md.

     OLD IDIOM: (void) cq_phi(e, 0.30)  [Rz keep-alive on the dead fmin]
     NEW IDIOM: if (e == 1.5) cq_phi(0.30)

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
     cq_template_fmin_f64_unc

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
/* slice_intrinsic_fpmath.c — Phase 7.1 iw81.4.b e2e link proof: the fp-math
   intrinsic family (FROZEN ABI). The ONLY layer that LINKS, so the only proof
   that the new generated fp symbols — the unary forward cq_template_floor_f64,
   the binary forward cq_template_fmin_f64, AND the binary void uncompute twin
   cq_template_fmin_f64_unc(out, a, b) — all resolve and signature-match the
   generated sibling ABI (cq_intrinsic_templates, in libcq_templates.a) at the
   `double` width (Rule 2, Rule 16). A green opt -verify + passing FileCheck on the
   .ll fixtures are NOT this proof.

   Errno-free builtins are used so clang -O1 reliably emits the `@llvm.*`
   intrinsic (not an errno-modeled libm @call) regardless of the target's
   -fmath-errno default: __builtin_floor -> @llvm.floor.f64, __builtin_fmin ->
   @llvm.minnum.f64.

   Two independent fp-math lineages in a `__attribute__((noinline))` helper (the
   noinline boundary is LOAD-BEARING: whole-DAG uncompute is gated OFF in `main`,
   and at -O1 clang would otherwise inline `slice` so the uncompute never runs —
   same discipline as slice_intrinsic_ctpop.c / slice_f16.c):

   (A) MEASURED unary floor — proves the FORWARD fp symbol. One f64 theta ->
       `@llvm.floor.f64` -> cq_template_floor_f64 -> cqrt_measure_f64.

   (B) DEAD binary fmin — proves the binary `_unc` TWIN + R-E source-liveness.
       Two f64 thetas -> `@llvm.minnum.f64` (result dead), kept alive past -O1 DCE
       by a `cq_phi` (Rz) whose own result is dropped. The whole-DAG uncompute
       spine reverses the dead fmin ONCE via cq_template_fmin_f64_unc(out, c, d)
       (recompute-and-XOR from the still-LIVE f64 sources c, d) and frees each rail
       ONLY AFTER its own `_unc` — never before (a source freed before its `_unc`
       is the silent-collapse class). No added measure, NO cqrt_copy_f64 (none
       exists: an fp carrier is an angle, never data).

   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
__attribute__((noinline))
void slice(double x, double y) {
    /* (A) measured unary floor — proves the forward f64 symbol. */
    double a = x; cq_theta(&a, 0.25); /* alloc f64 + ry */
    double b = __builtin_floor(a);    /* @llvm.floor.f64 -> cq_template_floor_f64 */
    (void) cq_measure(b);             /* -> cqrt_measure_f64 */

    /* (B) dead binary fmin — proves the binary `_unc` twin + source-liveness. */
    double c = x; cq_theta(&c, 0.10); /* alloc f64 + ry */
    double d = y; cq_theta(&d, 0.20); /* alloc f64 + ry */
    double e = __builtin_fmin(c, d);  /* @llvm.minnum.f64 QQ (dead) */
    if (e == 1.5) cq_phi(0.30);           /* Rz keep-alive; result dropped (dead) */
}
int main(void) { slice(1.5, 2.5); return 0; }
