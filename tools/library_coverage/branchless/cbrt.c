/* branchless/cbrt.c — bd 3c6m.10 (libm L1): the AUTHORED branchless soft-cbrt body
   the census injects for `cbrt` (Rule 18 source injection; owner body-source
   decision 2026-07-10 = hand-author per fn, the slice_branchless_exp model).
   This file SHADOWS openlibm's branchy s_cbrt.c in the census symbol index —
   EXACTLY FreeBSD/openlibm's algorithm core (Kahan's magic-constant bit-hack
   seed + one degree-4 polynomial step + one Newton step), with ONLY the
   data-dependent special-case BRANCHES removed (the subnormal/zero rescale and
   the inf/NaN guard at s_cbrt.c:52). ZERO selects, zero control flow — the seed's
   "divide the exponent by 3" is an integer op on the punned high word and the
   sign rides a bit (branchless), so the whole body is straight-line integer +
   fp opcodes the taint pass lowers directly.

   The e2e golden twin is tests/e2e/slice_branchless_cbrt.c (same body, inlined
   at the slice level) — keep the two in sync.

   Domain: finite NORMAL x (either sign) — cbrt is odd, so negatives ride the
   sign bit through the seed and every iteration. x == 0 / subnormal / inf / NaN
   are UNSPECIFIED (those are exactly the data-dependent branches this branchless
   body deliberately omits: openlibm rescales subnormals by 2^54 and returns
   x/x+x for inf/NaN). On the documented domain this is openlibm's own <1-ulp
   result (unchanged algorithm — only the special-case guards are gone).

   Compile like the openlibm corpus: `clang -g -O1 -emit-llvm -c` with NO
   -fno-builtin (a "no-builtins" definition attribute makes the probe caller's
   no-builtin-cbrt set a non-superset and the O2 inliner then refuses to inline
   the body: TLI areInlineCompatible, InlineCallerSupersetNoBuiltin). */
double cbrt(double x) {
    /* FreeBSD/openlibm s_cbrt.c degree-4 seed-refinement coefficients. */
    const double P0 =  1.87595182427177009643;   /* 3FFE03E6, 0F61E692 */
    const double P1 = -1.88497979543377169875;   /* BFFE28E0, 92F02420 */
    const double P2 =  1.621429720105354466140;   /* 3FF9F160, 4A49D6C2 */
    const double P3 = -0.758397934778766047437;   /* BFE844CB, BEE751D9 */
    const double P4 =  0.145996192886612446982;   /* 3FC2B000, D4E4EDD7 */

    unsigned long long ix;
    __builtin_memcpy(&ix, &x, 8);                       /* bitcast f64->i64        */
    unsigned long long sign = ix & 0x8000000000000000ULL;             /* sign(x)   */
    unsigned int hx = (unsigned int)((ix & 0x7FFFFFFFFFFFFFFFULL) >> 32); /* |x| hi word */

    /* Rough cbrt to 5 bits: integer-divide the biased exponent+mantissa word by
       3 and add Kahan's bias B1; reattach the sign. For finite normal x this
       "magically" yields 2^(e/3)*(1+(e%3+m)/3) to a max relative error ~1/32. */
    unsigned long long tbits =
        sign | ((unsigned long long)(hx / 3u + 715094163u) << 32);      /* + B1   */
    double t;
    __builtin_memcpy(&t, &tbits, 8);                    /* bitcast i64->f64        */

    /* New cbrt to 23 bits: t*P(t^3/x), P a degree-4 approximation to 1/cbrt(r). */
    double r = (t * t) * (t / x);
    t = t * ((P0 + r * (P1 + r * P2)) + ((r * r) * r) * (P3 + r * P4));

    /* Round t away from zero to 23 bits (pure integer bit op on the pattern —
       add the round-half bias at bit 31, then clear the low 30 mantissa bits). */
    unsigned long long ut;
    __builtin_memcpy(&ut, &t, 8);
    ut = (ut + 0x80000000ULL) & 0xFFFFFFFFC0000000ULL;
    __builtin_memcpy(&t, &ut, 8);

    /* One Newton step (solving t*t - x/t == 0) to 53 bits, error < 0.667 ulp. */
    double s  = t * t;                                  /* exact                  */
    double rr = x / s;
    double w  = t + t;                                  /* exact                  */
    rr = (rr - t) / (w + rr);
    return t + t * rr;
}
