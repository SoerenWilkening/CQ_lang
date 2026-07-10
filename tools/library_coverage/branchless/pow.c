/* branchless/pow.c — bd 3c6m.40 (libm L2-closure): the AUTHORED branchless pow body
   the census injects for `pow` (Rule 18 source injection; owner body-source decision
   2026-07-10 = hand-author per fn, the slice_branchless_exp model). This file SHADOWS
   openlibm's table-driven e_pow.c in the census symbol index.

   *** WHY openlibm's pow DECLINES. *** openlibm's e_pow.c is one of the branchiest
   libm bodies — a sign/parity/overflow special-case ladder around a table-driven
   log/exp with data-dependent indices (the nested tainted control flow + QROM the
   census flags). This body dissolves ALL of it with the L2-closure identity

       pow(x,y) = 2^(y·log2(x)) = exp2(y · log2(x))     [x > 0]

   and CALLS the authored branchless `log2` and `exp2` leaves — resolved by the census
   closure-link to branchless/{log2,exp2}.c (indexed first) and inlined; exp2 in turn
   calls the `exp` leaf (branchless/exp.c). log2 is fully branchless (bit-trick
   reduction + Horner, ZERO selects); exp2->exp contributes ONE fp-data round-bias
   select (the kjd1 accept shape) — so the whole body lowers with a single flag, no
   branches. Every taint mask (qc: log2(q); cq: log2(0.5) const-folds to -1, exp2(y*-1);
   qq: both) lowers.

   The e2e golden twins are tests/e2e/slice_branchless_pow{,_cq,_qq}.c — one per accepted
   taint mask (3c6m.48), same body with the log2/exp2/exp leaves inlined as static
   helpers (blog2/bexp2/bexp == the corpus twins). Keep all textually in sync.

   Domain: x > 0 (the principal real branch). Negative base, 0^0, and integer-exponent
   PARITY (which need the sign/parity special cases this branchless body omits) are
   UNSPECIFIED, as are the over/underflow octaves. On x > 0 this is the composition of
   two <~few-ulp leaves (log2 ~1 ulp, exp2 ~3e-6 rel); a trace-only runtime, so classical
   ulp is a SANITY check, not a gate — pow(0.5, 2) = 0.25, pow(2, 0.5) = sqrt(2).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
extern double log2(double);
extern double exp2(double);

double pow(double x, double y) {
    return exp2(y * log2(x));                           /* x^y = 2^(y·log2 x)      */
}
