/* slice_bitint.c — Phase 7.1 follow-up D5 (test_C_libtooling-m0yi) e2e link
   proof: a non-power-of-2 _BitInt(N) INTERMEDIATE round-trips with NO new ABI.

   FINDING (real clang 19.1.7 -O1, contra the plan's R-D assumption that clang
   emits a raw `add i40`): `unsigned _BitInt(40)` arithmetic rounds up to the i64
   storage width and emits the i40 wraparound as a stock high-bit mask
   `and i64 ..., 0xFFFFFFFFFF` (= 2^40-1) — both ops already have frozen templates
   (cq_template_add_i64 / cq_template_and_i64_hl), so the proposed
   cq_template_mask_<W> frozen family is unnecessary.

   This is the ONLY layer that LINKS, so the only proof that the round+mask gate
   stream AND the mask's void _unc twin (cq_template_and_i64_hl_unc) resolve and
   signature-match the generated ABI (Rule 2, Rule 16). Two lineages:

   (A) MEASURED unsigned _BitInt(40) add — proves the forward round+mask producers.
   (B) DEAD masked value kept alive by a cq_phi — proves the and-mask _unc twin
       (recompute-and-XOR from the live source) + the |0> free.

   cq_theta/cq_phi/cq_measure resolve from CQ.h (force-included by run_slice.sh). */
typedef unsigned _BitInt(40) u40;

__attribute__((noinline))
void slice(unsigned long x, unsigned long y) {
    /* (A) measured forward: (u40)a + (u40)b, then mask back to 40 bits. */
    unsigned long a = cq_theta(x, 0.25);
    unsigned long b = cq_theta(y, 0.50);
    u40 za = (u40)a;
    u40 zb = (u40)b;
    u40 zs = za + zb;                    /* i40 add — clang masks at 2^40 */
    (void) cq_measure((unsigned long)zs);

    /* (B) dead mask — proves the and-mask _unc + recompute-from-live-source. */
    unsigned long c = cq_theta(x, 0.10);
    u40 zc = (u40)c;                     /* and i64 c, 2^40-1 — dead */
    (void) cq_phi((unsigned long)zc, 0.30);   /* Rz keep-alive; result dropped */
}
int main(void) { slice(0xFFFFFFFFFFul, 1ul); return 0; }
