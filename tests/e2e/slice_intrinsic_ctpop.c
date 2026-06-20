/* slice_intrinsic_ctpop.c — Phase 7.1 Increment E e2e link proof, Class-2
   (non-injective pure total). The ONLY layer that LINKS, so the only proof that
   cq_template_ctpop_i32 AND its void `_unc` twin cq_template_ctpop_i32_unc(out,
   src) resolve and signature-match the generated sibling ABI (Rule 2, Rule 16).

   `__builtin_popcount` -> `@llvm.ctpop.i32`, a curated Class-2 op. The golden
   proves the central R-E source-liveness discipline: the dead ctpop is reversed
   by recomputing ctpop from its STILL-LIVE source (the `_unc` reads the source
   handle), and the source is uncomputed + freed ONLY AFTER its own `_unc` — never
   before (a source freed before its `_unc` is the silent-collapse class). No
   `_inv` (ctpop is not invertible). Two lineages in a `noinline` helper:

   (A) MEASURED ctpop — proves the FORWARD producer.
   (B) DEAD ctpop kept alive by a `cq_phi` — proves the `_unc` twin + source-live.

   cq_theta/cq_phi/cq_measure resolve from CQ.h (force-included by run_slice.sh). */
__attribute__((noinline))
void slice(unsigned x) {
    /* (A) measured forward ctpop. */
    unsigned a = cq_theta(x, 0.25);
    int b = __builtin_popcount(a);       /* llvm.ctpop.i32 -> cq_template_ctpop_i32 */
    (void) cq_measure(b);

    /* (B) dead ctpop — proves the `_unc` twin + recompute-from-live-source. */
    unsigned c = cq_theta(x, 0.10);
    int d = __builtin_popcount(c);        /* dead */
    (void) cq_phi(d, 0.30);               /* Rz keep-alive; result dropped */
}
int main(void) { slice(0x0f0f0f0fu); return 0; }
