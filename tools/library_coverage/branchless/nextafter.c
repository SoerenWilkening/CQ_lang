/* branchless/nextafter.c — bd 3c6m.39 (libm L1): the AUTHORED branchless nextafter
   body the census injects for `nextafter` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model). This file
   SHADOWS openlibm's branchy s_nextafter.c in the census symbol index.

   *** WHY openlibm's nextafter DECLINES. *** openlibm's s_nextafter.c is a ladder of
   data-dependent branches (x==y early-out, x==0 subnormal seed, over/underflow flag
   raises — the nested tainted control flow / the L5-shadow blocker). This body renders
   the one-ULP bit step FULLY ARITHMETIC (ZERO selects, ZERO branches):

       dir  = (y>x) - (y<x)          # +1 toward +inf, -1 toward -inf, 0 if x==y
       step = dir * (1 - 2*sign(x))  # bit pattern moves +dir for x>=0, -dir for x<0
       nextafter(x,y) = bitcast( bits(x) + step )

   For a POSITIVE x the bit pattern increases with value, so a step of +dir walks one
   ULP toward y; for a NEGATIVE x the ordering inverts, so the sign factor flips it. The
   two comparisons are fcmp->zext (not selects), the sign is a bit shift, and the combine
   is integer mul/add — so every taint mask (qc/cq/qq) lowers as straight-line opcodes,
   no tainted control. x==y falls out for free (dir==0 -> step==0 -> returns x).

   The e2e golden twins are tests/e2e/slice_branchless_nextafter{,_cq,_qq}.c — one per
   accepted taint mask (3c6m.48), same body inlined as the static `bnextafter` helper.

   Domain: finite NORMAL x != 0, finite y (the ±1 bit step ripples the exponent at
   binade boundaries correctly — the exponent field is contiguous with the mantissa in
   the bit pattern). UNSPECIFIED (the special cases this branchless body omits): x == ±0
   (openlibm seeds the smallest subnormal with sign(y); here +0 stepping toward -inf
   would underflow the magnitude to the all-ones NaN pattern), a NaN argument (openlibm
   returns NaN; here a NaN y gives dir = (y>x)-(y<x) = 0-0 = 0, so it returns x — the
   trace-only runtime never observes the value), and the DBL_MAX->+inf edge. On the
   contractual range it is EXACT (the ±1 bit step is nextafter's definition); no
   in-domain NaN/Inf.

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c`, NO -fno-builtin
   (see branchless/log.c for the inliner-compatibility reason). */
double nextafter(double x, double y) {
    unsigned long long ix;
    __builtin_memcpy(&ix, &x, 8);                      /* bitcast f64->i64        */
    long long up  = (long long)(y > x);                /* fcmp ogt -> zext (0/1)  */
    long long dn  = (long long)(y < x);                /* fcmp olt -> zext (0/1)  */
    long long dir = up - dn;                           /* +1 / -1 / 0 (value dir) */
    long long neg = (long long)(ix >> 63);             /* sign bit: 1 if x < 0    */
    long long step = dir * (1 - 2 * neg);              /* bit-pattern delta       */
    ix = ix + (unsigned long long)step;                /* one ULP toward y        */
    double out;
    __builtin_memcpy(&out, &ix, 8);                    /* bitcast i64->f64        */
    return out;
}
