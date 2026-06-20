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
   (B) DEAD bswap kept alive by a `cq_phi` — proves the `_unc` TWIN: the spine
       reverses it via cq_template_bswap_i32_unc (recompute from the live source)
       and frees the rail, with NO `_inv`, NO added measure.

   cq_theta/cq_phi/cq_measure resolve from CQ.h (force-included by run_slice.sh). */
__attribute__((noinline))
void slice(unsigned x) {
    /* (A) measured forward bswap. */
    unsigned a = cq_theta(x, 0.25);
    unsigned b = __builtin_bswap32(a);   /* llvm.bswap.i32 -> cq_template_bswap_i32 */
    (void) cq_measure(b);

    /* (B) dead bswap — proves the `_unc` twin. */
    unsigned c = cq_theta(x, 0.10);
    unsigned d = __builtin_bswap32(c);   /* dead */
    (void) cq_phi(d, 0.30);              /* Rz keep-alive; result dropped */
}
int main(void) { slice(0x12345678u); return 0; }
