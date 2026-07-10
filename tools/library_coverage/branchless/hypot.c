/* branchless/hypot.c — bd 3c6m.33 (libm L1): the AUTHORED branchless hypot body the
   census injects for `hypot` (Rule 18 source injection; owner body-source decision
   2026-07-10 = hand-author per fn, the slice_branchless_exp model). This file
   SHADOWS openlibm's word-surgery e_hypot.c in the census symbol index.

   *** WHY openlibm's hypot DECLINES. *** openlibm's e_hypot.c is a ladder of
   data-dependent branches on the exponent words (scale-by-2^k to dodge over/underflow,
   swap so |a|>=|b|, medium/large/tiny special cases — the nested tainted control flow
   the census flags). This body keeps the overflow-safe scaling but renders it
   branchless with the keep-set fmax/fmin:

       hi = fmax(|x|,|y|),  lo = fmin(|x|,|y|),  r = lo/hi
       hypot(x,y) = hi * sqrt(1 + r*r)

   Dividing by the LARGER magnitude keeps r in [0,1], so r*r never overflows and the
   sqrt argument stays in [1,2] — the standard overflow-safe form. fabs/fmax/fmin/sqrt
   are all hardware-kept (Rule 18); NO selects, NO branches — so it lowers for every
   taint mask (qc/cq/qq).

   The e2e golden twins are tests/e2e/slice_branchless_hypot{,_cq,_qq}.c — one per
   accepted taint mask (3c6m.48), same body inlined as the static `bhypot` helper.

   Domain: finite x,y NOT both zero. At x == y == 0, hi == 0 and r = 0/0 = NaN (the
   one in-domain singularity — hypot should be 0 there); (0,0) is UNSPECIFIED, exactly
   the special case the openlibm branch handles. On the rest of the finite plane the
   overflow-safe scaling keeps the result finite and it is openlibm's own <1-ulp
   value (unchanged algorithm — only the special-case branches are gone; accuracy is a
   SANITY check on a trace-only runtime, not a gate).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
double hypot(double x, double y) {
    double ax = __builtin_fabs(x);
    double ay = __builtin_fabs(y);
    double hi = __builtin_fmax(ax, ay);                /* larger magnitude        */
    double lo = __builtin_fmin(ax, ay);                /* smaller magnitude       */
    double r  = lo / hi;                               /* r in [0,1], no overflow */
    return hi * __builtin_sqrt(1.0 + r * r);           /* overflow-safe hypot     */
}
