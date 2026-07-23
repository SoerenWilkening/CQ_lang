/* slice_branchless_logl.c — bd 20xt.8 Inc 2 / the ld80 (x86_fp80) branchless-leaf
   e2e twin of tools/library_coverage/branchless/logl.c. An AUTHORED branchless
   soft-logl is inlined here as `blogl`, so clang -O1 inlines it to stock
   reversible OPCODES and the taint pass lowers those (no per-fn cq_template_logl).
   Owner-approved 2026-07-23 (recipe carve-out): a DISJOINT hybrid/authored-leaf
   provenance, NEVER quoted alongside the real-openlibm goldens; verification is
   e2e-golden-only and the census cell logl.f80 stays declined (NO census delta).

   openlibm's ld80 logl (e_logl.c) is a 23-block / 10-cond-br body — an
   isnan/isinf/x<=0 domain ladder, a frexpl by-ref call, and a two-arm
   (|e|<=2 vs |e|>2) polynomial split — whose branches become TAINTED control flow
   under the opaque quantum seed (not an acyclic clone). This body replaces it with
   a fully REGISTER-ONLY, BRANCHLESS evaluation of e_logl.c's small-exponent path
   log(1+f) = f − ½f² + f³P(f)/Q(f), taken UNCONDITIONALLY (that minimax is
   faithful over the whole centered-mantissa range 1/√2 ≤ 1+f < √2 for every
   exponent — the single-path simplification the f64 branchless/log.c makes).

   The mantissa/exponent split reads x's bits through a `union IEEEl2bits`, which
   clang -O1's SROA promotes to pure SSA integer surgery on the f80 (bitcast
   f80↔i80, lshr/shl 64, trunc/zext, and/or) — cq-lowering lowers those to the
   reversible cq_template_{bitcast,lshr,shl,and,or,trunc,zext}_i80/i64/i32 family,
   ALL register handles, NO Shadow/qram/alloca (a 10-byte fp80 memcpy is
   deliberately avoided). The √2/2 centering is the single constant-operand fp
   select hi = (m < SQRTH) ? 1 : 0 (the atan/erf/kjd1 fp-DATA select accept shape;
   a libm body mints no Rz/Ry, so it lowers via cqrt_copy_f80_controlled), and the
   exponent decrement / mantissa reduction are UNCONDITIONAL fp blends. e is kept
   an `int` and carried to fp with (long double)e = sitofp i32→f80. Faithful
   (≈1 ulp, trace-only sanity) for finite normal x>0; x≤0/±∞/NaN/subnormal
   UNSPECIFIED (the domain branches a branchless body omits).

   The corpus twin is tools/library_coverage/branchless/logl.c (same body) — keep
   the two textually in sync. */
static long double blogl(long double x) {
    const long double P0 = 4.5270000862445199635215E-5L;
    const long double P1 = 4.9854102823193375972212E-1L;
    const long double P2 = 6.5787325942061044846969E0L;
    const long double P3 = 2.9911919328553073277375E1L;
    const long double P4 = 6.0949667980987787057556E1L;
    const long double P5 = 5.7112963590585538103336E1L;
    const long double P6 = 2.0039553499201281259648E1L;
    const long double Q0 = 1.5062909083469192043167E1L;
    const long double Q1 = 8.3047565967967209469434E1L;
    const long double Q2 = 2.2176239823732856465394E2L;
    const long double Q3 = 3.0909872225312059774938E2L;
    const long double Q4 = 2.1642788614495947685003E2L;
    const long double Q5 = 6.0118660497603843919306E1L;
    const long double C1 = 6.9314575195312500000000E-1L;
    const long double C2 = 1.4286068203094172321215E-6L;
    const long double SQRTH = 0.70710678118654752440L;

    union { long double e; struct { unsigned int manl : 32; unsigned int manh : 32;
            unsigned int exp : 15; unsigned int sign : 1; unsigned int junkl : 16;
            unsigned int junkh : 32; } bits; } u;
    u.e = x;
    int e = (int)u.bits.exp - 16382;
    u.bits.exp = 16382;
    long double m = u.e;

    long double hi = (m < SQRTH) ? 1.0L : 0.0L;
    long double ef = (long double)e - hi;
    long double f  = hi * (2.0L * m - 1.0L) + (1.0L - hi) * (m - 1.0L);

    long double z  = f * f;
    long double Pf = ((((((P0 * f + P1) * f + P2) * f + P3) * f + P4) * f + P5) * f + P6);
    long double Qf = ((((((f + Q0) * f + Q1) * f + Q2) * f + Q3) * f + Q4) * f + Q5);
    long double y  = f * (z * Pf / Qf);
    y = y + ef * C2;
    long double r = y - 0.5L * z;
    r = r + f;
    r = r + ef * C1;
    return r;
}
long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(blogl(q));
}
int main(void) { (void) slice(); return 0; }
