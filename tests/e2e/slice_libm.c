/* slice_libm.c — bd 3c6m.2 e2e link proof: the curated DIRECT-libm math.h family
   (FROZEN ABI). The ONLY layer that LINKS, so the only proof that the new
   generated libm symbols — the same-width unary/binary forwards, the CROSS-WIDTH
   producers cq_template_ilogb_f64_to_i32 / cq_template_lrint_f64_to_i64, the
   MIXED-ARG producers cq_template_ldexp_f64_i32[_hl|_lh], AND their void `_unc`
   twins — all resolve and signature-match the generated sibling ABI
   (cq_libm_templates, in libcq_templates.a) through the runtime (Rule 2, Rule 16).
   A green opt -verify + passing FileCheck on the .ll fixtures are NOT this proof.

   Recognition splits two ways, one template surface: cbrt/atan2/ldexp/ilogb stay
   DIRECT `@<name>` libm calls (LibmLowering, exact name); __builtin_lrint is the
   `@llvm.lrint.i64.f64` INTRINSIC (IntrinsicLowering cross-width). __builtin_lrint
   forces the intrinsic regardless of the target's -fmath-errno default (same
   discipline as slice_intrinsic_fpmath's __builtin_floor).

   Lineages in a `__attribute__((noinline))` helper (the noinline boundary is
   LOAD-BEARING: whole-DAG uncompute is gated OFF in `main`, and at -O1 clang would
   otherwise inline `slice` so the uncompute never runs — same as the other slices):

   (A) MEASURED forwards — prove the FORWARD symbols (live terminals, no `_unc`):
       cbrt (same-unary), atan2 HL (same-binary, non-comm), ldexp HL (mixed-arg).
   (B) DEAD lineages — prove the `_unc` TWINS + R-E source-liveness. Each dead
       producer is kept alive past -O1 DCE by a `cq_phi` (Rz) whose own result is
       dropped; the whole-DAG uncompute spine reverses it ONCE via its `_unc`
       (recompute-and-XOR from the still-LIVE source), then frees each rail ONLY
       AFTER its own `_unc`: the CROSS-WIDTH ilogb (f64->i32) + lrint (f64->i64),
       and the MIXED-ARG ldexp LH (fp literal, tainted int exponent). No
       cqrt_copy_* under any fp carrier (an fp value is an angle, never data).

   cq_theta/cq_phi/cq_measure resolve from CQ.h, force-included by run_slice.sh. */
#include <math.h>

__attribute__((noinline))
void slice(double x, double y, int k) {
    /* (A) measured forwards. */
    double a  = cq_theta(x, 0.25);        /* alloc f64 + ry */
    double ca = cbrt(a);                  /* @cbrt -> cq_template_cbrt_f64 */
    (void) cq_measure(ca);                /* -> cqrt_measure_f64 */

    double b  = cq_theta(y, 0.35);        /* alloc f64 + ry */
    double at = atan2(b, 2.0);            /* @atan2 -> cq_template_atan2_f64_hl */
    (void) cq_measure(at);

    double c  = cq_theta(x, 0.45);        /* alloc f64 + ry */
    double ld = ldexp(c, 3);              /* @ldexp -> cq_template_ldexp_f64_i32_hl */
    (void) cq_measure(ld);

    /* (B) dead lineages — prove the `_unc` twins + source-liveness. */
    double d  = cq_theta(x, 0.10);        /* alloc f64 + ry */
    int    il = ilogb(d);                 /* f64->i32 cross-width (dead) */
    (void) cq_phi(il, 0.20);              /* Rz keep-alive; result dropped */

    double e  = cq_theta(y, 0.30);        /* alloc f64 + ry */
    long   lr = __builtin_lrint(e);       /* f64->i64 intrinsic cross-width (dead) */
    (void) cq_phi(lr, 0.40);              /* Rz keep-alive; result dropped */

    int    n  = cq_theta(k, 0.50);        /* alloc i32 + ry (tainted int exponent) */
    double lx = ldexp(4.0, n);            /* mixed-arg LH: fp literal, int handle (dead) */
    (void) cq_phi(lx, 0.60);              /* Rz keep-alive; result dropped */
}
int main(void) { slice(1.5, 2.5, 3); return 0; }
