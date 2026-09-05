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
    double a = cq_theta(x, 0.25);     /* alloc f64 + ry */
    double b = __builtin_floor(a);    /* @llvm.floor.f64 -> cq_template_floor_f64 */
    (void) cq_measure(b);             /* -> cqrt_measure_f64 */

    /* (B) dead binary fmin — proves the binary `_unc` twin + source-liveness. */
    double c = cq_theta(x, 0.10);     /* alloc f64 + ry */
    double d = cq_theta(y, 0.20);     /* alloc f64 + ry */
    double e = __builtin_fmin(c, d);  /* @llvm.minnum.f64 QQ (dead) */
    cq_phi(0.30);           /* Rz keep-alive; result dropped (dead) */
}
int main(void) { slice(1.5, 2.5); return 0; }
