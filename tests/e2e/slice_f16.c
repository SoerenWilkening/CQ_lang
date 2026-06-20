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
    _Float16 a = cq_theta(x, 0.25);   /* alloc f16 + ry */
    _Float16 b = cq_theta(y, 0.50);   /* alloc f16 + ry */
    _Float16 s = a + b;               /* fadd half QQ -> cq_template_fadd_f16 */
    (void) cq_measure(s);             /* -> cqrt_measure_f16 */

    /* (B) dead, unmeasured Q+Q fadd — proves the `_unc` twin. */
    _Float16 p = cq_theta(x, 0.10);   /* alloc f16 + ry */
    _Float16 q = cq_theta(y, 0.20);   /* alloc f16 + ry */
    _Float16 d = p + q;               /* fadd half QQ (dead) */
    (void) cq_phi(d, 0.30);           /* Rz keep-alive; result dropped (dead) */
}
int main(void) { slice((_Float16)1.5, (_Float16)2.5); return 0; }
