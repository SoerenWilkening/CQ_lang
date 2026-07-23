/* branchless/cosl.c — bd 20xt.8 Inc 1 (Bennett-parity ld80 leaf): the AUTHORED
   branchless f80 (long double) cos body, the x86_fp80 port of branchless/cos.c.
   Owner-approved 2026-07-23 (recipe carve-out); a DISJOINT hybrid/authored-leaf
   provenance, NEVER quoted with real-openlibm goldens, and the census cell
   cosl.f80 stays DECLINED (the ld80 census injects the REAL openlibm cosl from the
   bitcode corpus, not this dir) — NO census-number delta.

   *** WHY openlibm's cosl DECLINES. *** identical to sinl — openlibm's Payne–Hanek
   __kernel_rem_pio2 large-argument reduction uses alloca [20 x i32]/[20 x double]
   working arrays with tainted dynamic-index stores inside bounded loops (Bennett
   MUX-EXCH, ROADMAP 7.5 post-freeze). This body replaces it with a REGISTER-ONLY,
   BRANCHLESS 2-term Cody–Waite reduction; see branchless/sinl.c for the full
   derivation. cos and sin share the SAME reduction and the SAME k_sinl/k_cosl
   kernels — they differ only in the quadrant offset.

   *** cos = sin(x + π/2). *** Adding π/2 leaves the reduced argument y unchanged
   (fn increases by exactly 1, y = (x+π/2) − (fn+1)·π/2 = x − fn·π/2) and shifts
   the quadrant by +1. So cos is authored as the branchless/sinl.c quadrant/sign
   code applied to (fn+1): qf = (fn+1) mod 4 feeds the SAME sinl useS/sgn map, so
   per the SHIFTED quadrant q'=(fn+1)mod4 the kernel output is q'=0:+sin(y)
   q'=1:+cos(y) q'=2:−sin(y) q'=3:−cos(y) — which is exactly cos(x) per the
   ORIGINAL quadrant q=fn mod4 (q=0:+cos, q=1:−sin, q=2:−cos, q=3:+sin). NOTE the
   value list is q'-indexed here (do NOT relabel it q — see the git history nit):
   via the same useS=(par<0.5)?1:0 kernel pick and
   sgn=(half<0.5)?1:−1 sign — every comparison a `<` against a CONSTANT, so clang
   -O1 keeps them speculatable `select`s (never branches; the equality form
   par==half WOULD branch-ify — see branchless/sinl.c). Both kernels are computed
   unconditionally and blended by the UNCONDITIONAL weighted expression
   sgn·(useS·S + (1−useS)·C) — the atan.c/erf.c const-select-weight pattern, the
   kjd1 fp-DATA select accept shape (a libm body mints no Rz/Ry; each f80 select
   lowers via cqrt_copy_f80_controlled). The keep-set floorl/rintl/fminl/fmaxl
   leaves are pure-register at f80 (cq-lowering rewrites @llvm.{floor,rint,minnum,
   maxnum}.f80 to cq_template_*_f80 before codegen; no libcall, no Shadow).

   *** FINITE OVER THE WHOLE DOMAIN. *** yc = fmaxl(-π/4, fminl(y, π/4)) with the
   NaN-suppressing keep-set fminl/fmaxl — a NEAR-no-op on the faithful range and a
   finite bound beyond it, so cos returns a finite value in [-1,1] for EVERY long
   double including ±∞/NaN. No in-domain NaN/Inf; the branchless range-reduction
   limit surfaces only as reduced ACCURACY for |x| ≳ 5.27e7.

   The e2e golden twin is tests/e2e/slice_branchless_cosl.c (same body, inlined at
   the slice level as `bcosl`) — keep the two textually in sync. Accuracy is a
   trace-only SANITY check, not a gate: matches host libm cosl to a few ulp for
   |x| ≲ 5.27e7; beyond that finite but unspecified (the Payne–Hanek path this body
   omits). */
long double cosl(long double x) {
    const long double invpio2 = 6.36619772367581343076e-01L; /* 2/π, 64-bit        */
    const double      pio2_1  = 1.57079632679597125389e+00;  /* π/2, first 39 bits */
    const long double pio2_1t = -1.07463465549719416346e-12L;/* π/2 − pio2_1 (tail)*/
    const long double PIO4    = 0.78539816339744830962L;     /* π/4 clamp guard    */
    const long double S1 = -0.166666666666666666671L;
    const double      S2 =  0.0083333333333333332,       S3 = -0.00019841269841269427,
                      S4 =  0.0000027557319223597490,    S5 = -0.000000025052108218074604,
                      S6 =  1.6059006598854211e-10,       S7 = -7.6429779983024564e-13,
                      S8 =  2.6174587166648325e-15;
    const long double C1 =  0.0416666666666666666136L;
    const double      C2 = -0.0013888888888888874,       C3 =  0.000024801587301571716,
                      C4 = -0.00000027557319215507120,   C5 =  0.0000000020876754400407278,
                      C6 = -1.1470297442401303e-11,       C7 =  4.7383039476436467e-14;

    long double fn = __builtin_rintl(x * invpio2);              /* keep-set leaf     */
    long double y  = (x - fn * pio2_1) - fn * pio2_1t;          /* 2-term Cody–Waite */
    long double yc = __builtin_fmaxl(-PIO4, __builtin_fminl(y, PIO4)); /* finite guard */

    long double z  = yc * yc;
    long double rs = S2 + z*(S3 + z*(S4 + z*(S5 + z*(S6 + z*(S7 + z*S8)))));
    long double v  = z * yc;
    long double S  = yc + v*(S1 + z*rs);                        /* sin(yc)           */
    long double rc = z*(C1 + z*(C2 + z*(C3 + z*(C4 + z*(C5 + z*(C6 + z*C7))))));
    long double hz = 0.5L * z, wc = 1.0L - hz;
    long double C  = wc + (((1.0L - wc) - hz) + z * rc);        /* cos(yc)           */

    /* cos = sin(x+π/2): sin-weight code on the +1-shifted quadrant. All-`<`-const
       selects (never the branch-ifying equality form).                           */
    long double fq   = fn + 1.0L;
    long double qf   = fq - 4.0L * __builtin_floorl(fq * 0.25L);
    long double half = __builtin_floorl(qf * 0.5L);
    long double par  = qf - 2.0L * half;
    long double useS = (par  < 0.5L) ? 1.0L : 0.0L;           /* even shifted quad → sin */
    long double sgn  = (half < 0.5L) ? 1.0L : -1.0L;
    long double mag  = useS * S + (1.0L - useS) * C;
    return sgn * mag;
}
