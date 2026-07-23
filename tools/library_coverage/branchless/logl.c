/* branchless/logl.c — bd 20xt.8 Inc 2 (Bennett-parity ld80 leaf): the AUTHORED
   branchless f80 (long double) natural-log body, the x86_fp80 companion of the
   f64 branchless/log.c. Owner-approved 2026-07-23 (recipe carve-out): a hybrid
   slice (real openlibm lgammal_r outer + AUTHORED branchless f80 sinl/cosl/logl
   leaves) is an accepted body-source, matching the f64 owner body-source decision
   2026-07-10 and Bennett.jl's SoftFloatLib. This body is a DISJOINT
   hybrid/authored-leaf provenance — NEVER quoted alongside the real-openlibm
   goldens, and the census cell logl.f80 stays DECLINED (the ld80 census injects
   the REAL openlibm logl from the bitcode corpus, not this dir), so there is NO
   census-number delta; verification is e2e-golden-only.

   *** WHY openlibm's logl DECLINES. *** openlibm's ld80 logl (e_logl.c) is a
   23-block / 10-cond-br body: an isnan/isinf/x<=0 domain ladder, a frexpl by-ref
   call, and a two-arm (|e|<=2 vs |e|>2) polynomial split. Under quantum lift the
   opaque taint seed makes those data-dependent branches TAINTED control flow, and
   the by-ref frexpl escape compounds it — not lowerable as an acyclic clone
   today. This body replaces the whole thing with a REGISTER-ONLY, BRANCHLESS
   evaluation of e_logl.c's *small-exponent* path (log(1+f) = f − ½f² + f³P(f)/Q(f))
   taken UNCONDITIONALLY: that minimax polynomial is faithful over the FULL
   centered-mantissa range 1/√2 ≤ 1+f < √2 for EVERY exponent (the ld80 comment's
   peak relative error 2.32e-20 is a property of the mantissa range, not of |e|),
   so dropping the |e|>2 atanh arm costs no faithfulness — exactly the single-path
   simplification the f64 branchless/log.c makes.

   *** THE frexp SPLIT IS A REGISTER BIT-CAST, NOT A memcpy. *** The mantissa/
   exponent split reads x's raw bits through a `union IEEEl2bits` (the amd64 fpmath
   layout: manl:32 manh:32 exp:15 sign:1). clang -O1's SROA promotes the union
   round-trip (store f80 · load i64@8 · rewrite exp · reload f80) to pure SSA
   integer surgery on the f80 — bitcast f80↔i80, lshr/shl 64, trunc/zext, and/or —
   which cq-lowering lowers to the reversible cq_template_{bitcast,lshr,shl,and,or,
   trunc,zext}_i80/i64/i32 family, ALL register handles, NO Shadow/qram/alloca. A
   10-byte fp80 __builtin_memcpy is DELIBERATELY avoided (it straddles the 80→128
   padding into a pattern SROA cannot always promote — the kMsgStore risk the
   recipe warns about). The exponent is recovered as `e = (exp & 0x7FFF) − 16382`
   (frexp convention: mantissa in [0.5,1)); the mantissa is rebuilt by overwriting
   the exponent field with 16382 so m ∈ [0.5,1). k is carried to fp with a plain
   `(long double)e` = sitofp i32→x86_fp80 (an i80→fp convert is NOT supported —
   keep e an `int`).

   *** THE √2/2 CENTERING IS A CONST-SELECT, NOT A BRANCH. *** e_logl.c's
   `if (m < SQRTH) { e−−; f = 2m−1; } else f = m−1;` becomes the single
   constant-operand fp select hi = (m < SQRTH) ? 1 : 0 (a `<` against a literal is
   speculatable, so clang -O1 keeps it a `select`, never a branch — the atan/erf/
   kjd1 fp-DATA select accept shape; a libm body mints no Rz/Ry so the fcmp-cond /
   const-arm shape applies, lowering via cqrt_copy_f80_controlled). The exponent
   decrement and the mantissa reduction are then the UNCONDITIONAL fp blends
   ef = e − hi and f = hi·(2m−1) + (1−hi)·(m−1) — no second comparison, no
   equality-of-computed-values select (which SimplifyCFG would branch-ify).

   *** COEFFICIENTS are e_logl.c's ld80 P[7]/Q[6] and the two-constant ln2 split
   C1/C2 *** (the small-exponent path, verbatim). P is __polevll(f,P,6) = a degree-6
   Horner; Q is __p1evll(f,Q,6) = a MONIC degree-6 Horner (implicit leading 1).
   The ln2 reconstruction adds the small tail ef·C2 to the polynomial FIRST, then
   the large head ef·C1 LAST (e_logl.c's ordering) so the exact-ish C1 term
   dominates with full precision. ½f² is `0.5L*z` (e_logl.c's ldexpl(z,−1)).

   *** DOMAIN. *** Faithful (≈1 ulp, trace-only sanity — the runtime is trace-only)
   for finite NORMAL x > 0. x ≤ 0 / ±∞ / NaN / subnormal are UNSPECIFIED — exactly
   the data-dependent domain branches a branchless injected body omits (the f64
   branchless/log.c makes the identical exclusion). No floor/rint needed in log.

   The e2e golden twin is tests/e2e/slice_branchless_logl.c (same body, inlined at
   the slice level as `blogl`) — keep the two textually in sync. Compile like the
   rest of the corpus (inject_census.py: blanket -fno-builtin; the union access is
   plain C and unaffected). */
long double logl(long double x) {
    /* e_logl.c ld80 small-exponent path: log(1+f) = f − ½f² + f³·P(f)/Q(f). */
    const long double P0 = 4.5270000862445199635215E-5L;
    const long double P1 = 4.9854102823193375972212E-1L;
    const long double P2 = 6.5787325942061044846969E0L;
    const long double P3 = 2.9911919328553073277375E1L;
    const long double P4 = 6.0949667980987787057556E1L;
    const long double P5 = 5.7112963590585538103336E1L;
    const long double P6 = 2.0039553499201281259648E1L;
    const long double Q0 = 1.5062909083469192043167E1L;   /* Q is MONIC (implicit 1) */
    const long double Q1 = 8.3047565967967209469434E1L;
    const long double Q2 = 2.2176239823732856465394E2L;
    const long double Q3 = 3.0909872225312059774938E2L;
    const long double Q4 = 2.1642788614495947685003E2L;
    const long double Q5 = 6.0118660497603843919306E1L;
    const long double C1 = 6.9314575195312500000000E-1L;  /* ln2 head (exact-ish)   */
    const long double C2 = 1.4286068203094172321215E-6L;  /* ln2 tail               */
    const long double SQRTH = 0.70710678118654752440L;    /* 1/√2                   */

    /* frexp-style split via union IEEEl2bits (amd64 fpmath layout) — a register
       bit-cast under SROA, NOT a 10-byte memcpy. e uses the frexp convention
       (mantissa in [0.5,1)), so the exponent bias is 16382 = 16383 − 1.          */
    union { long double e; struct { unsigned int manl : 32; unsigned int manh : 32;
            unsigned int exp : 15; unsigned int sign : 1; unsigned int junkl : 16;
            unsigned int junkh : 32; } bits; } u;
    u.e = x;
    int e = (int)u.bits.exp - 16382;   /* exponent, mantissa forced into [0.5,1)   */
    u.bits.exp = 16382;                /* overwrite exponent → m ∈ [0.5,1)         */
    long double m = u.e;

    /* √2/2 centering as a constant-operand fp select (never a branch): for
       m < √2/2 use f = 2m−1 and e−−, else f = m−1.                               */
    long double hi = (m < SQRTH) ? 1.0L : 0.0L;
    long double ef = (long double)e - hi;                       /* sitofp i32→f80  */
    long double f  = hi * (2.0L * m - 1.0L) + (1.0L - hi) * (m - 1.0L);

    long double z  = f * f;
    long double Pf = ((((((P0 * f + P1) * f + P2) * f + P3) * f + P4) * f + P5) * f + P6);
    long double Qf = ((((((f + Q0) * f + Q1) * f + Q2) * f + Q3) * f + Q4) * f + Q5);
    long double y  = f * (z * Pf / Qf);
    y = y + ef * C2;                   /* small tail first                         */
    long double r = y - 0.5L * z;      /* − ½f²  (ldexpl(z,−1))                    */
    r = r + f;
    r = r + ef * C1;                   /* large head last (full-precision ln2)     */
    return r;
}
