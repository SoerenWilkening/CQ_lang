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
    cq_phi(0.30);   /* Rz keep-alive; result dropped */
}
int main(void) { slice(0xFFFFFFFFFFul, 1ul); return 0; }
