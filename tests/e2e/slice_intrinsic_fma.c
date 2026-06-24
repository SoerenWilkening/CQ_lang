/* slice_intrinsic_fma.c — Phase 7.1 wd2p e2e link proof: the ternary fma family
   (FROZEN ABI, the FIRST 3-operand template). The ONLY layer that LINKS, so the
   only proof that the new generated fma symbols — the QQQ forward
   cq_template_fma_f64, the QLQ forward cq_template_fma_f64_qlq, AND the QLQ void
   uncompute twin cq_template_fma_f64_qlq_unc(out, a, b_classical, c) — all resolve
   and signature-match the generated sibling ABI (cq_intrinsic_templates, in
   libcq_templates.a) at the `double` width (Rule 2, Rule 16). A green opt -verify
   + passing FileCheck on the .ll fixtures are NOT this proof.

   Two independent fma lineages in a `__attribute__((noinline))` helper (the
   noinline boundary is LOAD-BEARING: whole-DAG uncompute is gated OFF in `main`,
   and at -O1 clang would otherwise inline `slice` so the uncompute never runs —
   same discipline as slice_intrinsic_fpmath.c / slice_intrinsic_ctpop.c):

   (A) MEASURED contracted `a*b + c` — proves the FORWARD QQQ symbol AND the
       headline reason wd2p is core: at default -O1 ordinary `a*b+c` CONTRACTS to
       `@llvm.fmuladd.f64` (verified), which without wd2p declines at
       kMsgUnknownCallee. Three f64 thetas -> @llvm.fmuladd.f64 (all handles) ->
       cq_template_fma_f64 -> cqrt_measure_f64. The measured lineage is left
       allocated (a measured rail is never proven |0> — Rule 6).

   (B) DEAD must-fuse QLQ fma — proves the MIXED forward + the MIXED `_unc` twin +
       R-E source-liveness. Two f64 thetas + a literal 3.0 -> `__builtin_fma(d, 3.0,
       e)` = @llvm.fma.f64(d, 3.0, e) (the commutative product canonicalized
       handle-before-literal -> QLQ), result dead, kept alive past -O1 DCE by a
       `cq_phi` (Rz) whose own result is dropped. The whole-DAG uncompute spine
       reverses the dead fma ONCE via cq_template_fma_f64_qlq_unc(out, d, 3.0, e)
       (recompute-and-XOR from the still-LIVE f64 sources d, e and the literal 3.0)
       and frees each rail ONLY AFTER its own `_unc` — never before (a source freed
       before its `_unc` is the silent-collapse class, Rule 8). No added measure, NO
       cqrt_copy_f64 (an fp carrier is an angle, never data).

   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
__attribute__((noinline))
void slice(double x, double y, double z) {
    /* (A) measured contracted a*b+c -> @llvm.fmuladd.f64 (QQQ), forward symbol. */
    double a = cq_theta(x, 0.25);     /* alloc f64 + ry */
    double b = cq_theta(y, 0.50);     /* alloc f64 + ry */
    double c = cq_theta(z, 0.75);     /* alloc f64 + ry */
    double r = a * b + c;             /* @llvm.fmuladd.f64 -> cq_template_fma_f64 */
    (void) cq_measure(r);             /* -> cqrt_measure_f64 */

    /* (B) dead QLQ fma -> mixed forward + mixed `_unc` twin + source-liveness. */
    double d = cq_theta(x, 0.10);     /* alloc f64 + ry */
    double e = cq_theta(y, 0.20);     /* alloc f64 + ry */
    double f = __builtin_fma(d, 3.0, e);  /* @llvm.fma.f64(d, 3.0, e) -> QLQ (dead) */
    (void) cq_phi(f, 0.30);           /* Rz keep-alive; result dropped (dead) */
}
int main(void) { slice(1.5, 2.5, 3.5); return 0; }
