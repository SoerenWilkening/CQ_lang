/* branchless/sinl.c — bd 20xt.8 Inc 1 (Bennett-parity ld80 leaf): the AUTHORED
   branchless f80 (long double) sin body, the x86_fp80 port of branchless/sin.c.
   Owner-approved 2026-07-23 (recipe carve-out): a hybrid slice (real openlibm
   lgammal_r outer + AUTHORED branchless f80 sinl/cosl/logl leaves) is an accepted
   body-source, matching the f64 owner body-source decision 2026-07-10 and
   Bennett.jl's SoftFloatLib. This body is a DISJOINT hybrid/authored-leaf
   provenance — NEVER quoted alongside the real-openlibm goldens, and the census
   cell sinl.f80 stays DECLINED (the ld80 census injects the REAL openlibm sinl
   from the bitcode corpus, not this dir), so there is NO census-number delta.

   *** WHY openlibm's sinl DECLINES. *** openlibm reduces an arbitrary x to
   [-π/4,π/4] with the full __kernel_rem_pio2 Payne–Hanek large-argument reduction:
   alloca [20 x i32]/[20 x double] working arrays with DYNAMIC-INDEX (tainted)
   stores inside bounded loops (e_rem_pio2l.h → __kernel_rem_pio2). That is
   Bennett's quantum-indexed MUX-EXCH memory-write strategy, which CQ ROADMAP 7.5
   defers post-freeze — not lowerable today. This body replaces it with a fully
   REGISTER-ONLY, BRANCHLESS 2-term Cody–Waite reduction (no scratch array, no
   branches), exactly as Bennett.jl's SoftFloatLib does:

       fn = rintl(x · 2/π)                 nearest quarter-turn count
       y  = (x − fn·pio2_1) − fn·pio2_1t   reduced arg in [-π/4,π/4] (2-term C-W)

   pio2_1 is π/2 truncated to 39 bits (kept `double` so fn·pio2_1 is EXACT for
   |fn| ≲ 2^25) and pio2_1t = π/2 − pio2_1 its tail — so the two-term subtraction
   cancels ≈102 bits of π/2 (e_rem_pio2l.h §1st round), faithful for
   |x| ≲ 2^25·(π/2) ≈ 5.27e7 (the ld80 medium-size threshold). NOTE the ld80 tail
   is NEGATIVE and a DIFFERENT value from the f64 6.077e-11 (do NOT reuse the f64
   constant). Then fdlibm's ld80 degree-8 k_sinl / degree-7 k_cosl minimax kernels
   on the reduced arg (grown from the f64 6-term kernels, which are NOT faithful at
   f80), and the QUADRANT (fn mod 4) selects the answer:
       q=0:+sin(y)  q=1:+cos(y)  q=2:−sin(y)  q=3:−cos(y).

   *** WHY THE QUADRANT IS FP CONST-SELECTS, NOT INTEGER + DATA-SELECT. *** The
   quadrant is derived ENTIRELY in fp — qf = fn − 4·floorl(fn/4) ∈ {0,1,2,3},
   par = qf mod 2, half = floorl(qf/2) — via the keep-set floorl, so there is no
   fptosi/int-mask. Both kernels S=k_sinl(y), C=k_cosl(y) are computed
   UNCONDITIONALLY and blended by CONSTANT-operand fp selects: useS=(par<0.5)?1:0
   picks the kernel, sgn=(half<0.5)?1:−1 the sign, and the answer is the
   UNCONDITIONAL weighted expression  sgn·(useS·S + (1−useS)·C). A constant-operand
   select on a `<` against a literal is speculatable, so clang -O1 keeps it a
   `select` (never a branch) — the atan.c/erf.c pattern (a libm body mints no
   Rz/Ry, so the kjd1 fp-DATA select accept shape applies: fcmp condition, no
   rotation lineage; each f80 select lowers via cqrt_copy_f80_controlled). An
   EQUALITY-of-two-computed-values select (par==half) IS branch-ified by
   SimplifyCFG — so cos(x) is authored (branchless/cosl.c) as this same sin-weight
   code applied to (fn+1), keeping every comparison a `<` against a constant.

   *** FLOOR/RINT/FMIN/FMAX AT F80 ARE PURE-REGISTER. *** The f80-floor-libcall
   worry is MOOT: clang codegen turns __builtin_floorl into `callq _floorl`, BUT
   cq-lowering rewrites @llvm.floor.f80/@llvm.rint.f80/@llvm.minnum.f80/
   @llvm.maxnum.f80 to cq_template_{floor,rint,fmin,fmax}_f80 BEFORE codegen;
   curated f80 bodies live in runtime/cq_intrinsic_templates.c and LINK. Use the
   __builtin_* spellings (l-suffix), NEVER bare floorl/rintl (the census injects
   the branchy s_floorl.c for the bare name → declines). No union/i80/Shadow/memcpy
   anywhere — the whole body is registers.

   *** FINITE OVER THE WHOLE DOMAIN. *** The reduced arg is clamped
   yc = fmaxl(-π/4, fminl(y, π/4)) with the NaN-suppressing keep-set fminl/fmaxl:
   a NEAR-no-op on the faithful range (it fires only at the rare odd·π/4
   rint-boundary input, a ~1e-15 effect), and a finite bound beyond it, so the
   body returns a FINITE value in [-1,1] for EVERY long double including ±∞/NaN
   (fminl/fmaxl return the non-NaN operand). No in-domain NaN/Inf; the branchless
   range-reduction limit surfaces only as reduced ACCURACY for |x| ≳ 5.27e7. ±0 →
   +0 (no final copysign — a signed-zero UNSPEC edge, harmless).

   The e2e golden twin is tests/e2e/slice_branchless_sinl.c (same body, inlined at
   the slice level as `bsinl`) — keep the two textually in sync. Accuracy is a
   trace-only SANITY check, not a gate (runtime is trace-only): matches host libm
   sinl to a few ulp for |x| ≲ 5.27e7; beyond that finite but unspecified (the
   Payne–Hanek path this body deliberately omits). Compile like the rest of the
   corpus (inject_census.py: blanket -fno-builtin; __builtin_* leaves are explicit
   and unaffected). */
long double sinl(long double x) {
    const long double invpio2 = 6.36619772367581343076e-01L; /* 2/π, 64-bit        */
    const double      pio2_1  = 1.57079632679597125389e+00;  /* π/2, first 39 bits */
    const long double pio2_1t = -1.07463465549719416346e-12L;/* π/2 − pio2_1 (tail)*/
    const long double PIO4    = 0.78539816339744830962L;     /* π/4 clamp guard    */
    /* fdlibm ld80 k_sinl degree-8 minimax (ld80/k_sinl.c).                        */
    const long double S1 = -0.166666666666666666671L;
    const double      S2 =  0.0083333333333333332,       S3 = -0.00019841269841269427,
                      S4 =  0.0000027557319223597490,    S5 = -0.000000025052108218074604,
                      S6 =  1.6059006598854211e-10,       S7 = -7.6429779983024564e-13,
                      S8 =  2.6174587166648325e-15;
    /* fdlibm ld80 k_cosl degree-7 minimax (ld80/k_cosl.c).                        */
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

    /* quadrant in fp (no fptosi): qf = fn mod 4 ∈ {0,1,2,3}, par = qf mod 2,
       half = floorl(qf/2). Kernel + sign by constant-operand fp selects.          */
    long double qf   = fn - 4.0L * __builtin_floorl(fn * 0.25L);
    long double half = __builtin_floorl(qf * 0.5L);
    long double par  = qf - 2.0L * half;
    long double useS = (par  < 0.5L) ? 1.0L : 0.0L;            /* even quadrant → sin */
    long double sgn  = (half < 0.5L) ? 1.0L : -1.0L;          /* q≥2 → negate       */
    long double mag  = useS * S + (1.0L - useS) * C;
    return sgn * mag;
}
