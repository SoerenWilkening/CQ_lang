/* branchless/tanl.c — bd 20xt.9 (Bennett-parity ld80 leaf): the AUTHORED branchless
   f80 (long double) tan body, the x86_fp80 port of branchless/tan.c and the missing
   trio leaf beside branchless/sinl.c + cosl.c. Owner-approved branchless-leaf category
   (bd 20xt.8, memory branchless-f80-leaf-recipe): a DISJOINT hybrid/authored-leaf
   provenance — NEVER quoted alongside the real-openlibm goldens, and the census cell
   tanl.f80 stays DECLINED (the ld80 census injects the REAL openlibm tanl from the
   bitcode corpus, not this dir), so there is NO census-number delta. Bennett-gated:
   tan is backed by Bennett's `soft_tan` (SoftFloat export), so this leaf is on the
   parity path, not a Bennett-unbacked overreach.

   *** WHY openlibm's tanl DECLINES. *** Identical to sinl/cosl: openlibm reduces an
   arbitrary x to [-π/4,π/4] with the full __kernel_rem_pio2 Payne–Hanek reduction
   (alloca [20 x i32]/[20 x double] working arrays with DYNAMIC-INDEX tainted stores
   inside bounded loops — Bennett's MUX-EXCH memory-write strategy, ROADMAP 7.5
   deferred). This body replaces it with a fully REGISTER-ONLY, BRANCHLESS 2-term
   Cody–Waite reduction, exactly as Bennett.jl's SoftFloatLib does — reusing sinl.c's
   PROVEN f80 reduction constants + k_sinl/k_cosl kernels verbatim.

   *** DESIGN NOTE — RATIO (S/C), NOT the openlibm k_tanl polynomial. *** The bd 20xt.9
   ticket text mentioned "k_tanl T-coefficients + odd-quadrant reciprocal via fdiv."
   That path is NOT taken, deliberately: openlibm's __kernel_tanl (ld80/k_tanl.c) is
   BRANCHY (an `if (fabsl(x) >= 0.67434)` pio4-fold plus `iy`/`i` branches) and its
   polynomial is faithful only on [-0.67434, 0.67434] — NARROWER than the [-π/4,π/4]
   that Cody–Waite produces. Dropping the fold to make it branchless would lose
   faithfulness near ±π/4; keeping the fold reintroduces a data-dependent branch (→
   declines). So instead this body PORTS branchless/tan.c's RATIO construction, which
   is faithful across the WHOLE reduced range and reuses kernels already e2e-verified
   in sinl.c: tan is reconstructed from the SAME k_sinl/k_cosl kernels — no k_tan
   table, no scratch memory, no branches. (Recorded on bd 20xt.9 for owner visibility.)

   *** tan IS π-PERIODIC — ONLY THE PARITY OF fn MATTERS. *** With fn = rintl(x·2/π)
   and reduced arg y = x − fn·π/2 ∈ [-π/4,π/4], and since tan has period π (not 2π),
   tan(x) depends ONLY on fn mod 2:
       fn even : tan(x) = tan(y)     =  sin(y)/cos(y)  =  S/C
       fn odd  : tan(x) = tan(y+π/2) = -cot(y)         = -C/S
   No half/sign 4-way quadrant business (that is sinl/cosl's concern) — tan needs one
   parity bit. cos(y) ∈ [√2/2,1] is never near 0 so S/C is stable; C/S blows up only
   as y→0 in the ODD case, which is exactly x → an odd multiple of π/2, the genuine
   POLE of tan (→ ±∞, correct).

   *** WHY PARITY IS FP CONST-SELECT WEIGHTS, NOT INTEGER + DATA-SELECT. *** par is
   derived ENTIRELY in fp — par = fn − 2·floorl(fn/2) ∈ {0,1} — via the keep-set
   floorl (no fptosi/int-mask). Both S=k_sinl(yc), C=k_cosl(yc) are computed
   UNCONDITIONALLY, and the two ratio operands are built by a CONSTANT-operand fp
   select feeding UNCONDITIONAL weighted sums with ONE division:
       useT = (par < 0.5) ? 1 : 0            even quadrant → tan = S/C
       num  = useT·S + (1−useT)·(−C)         S (even)  |  −C (odd)
       den  = useT·C + (1−useT)·  S          C (even)  |   S (odd)
       tan  = num / den                      ONE unconditional fdiv (cq_template_fdiv_f80 QQ)
   A constant-operand select on a `<` against a literal is speculatable, so clang -O1
   keeps it a `select` (never a branch) — the sinl.c/atan.c pattern (a libm body mints
   no Rz/Ry, so the kjd1 fp-DATA select accept shape applies: fcmp condition, no
   rotation lineage; each f80 select lowers via cqrt_copy_f80_controlled). num/den are
   UNCONDITIONAL arithmetic over always-computed S,C so clang cannot branch-ify a
   costly arm (the comparison is `<` against a CONSTANT, never equality of two computed
   values — the SimplifyCFG branch-ify trap that forces cosl.c to be authored separately).

   *** FLOOR/RINT/FMIN/FMAX AT F80 ARE PURE-REGISTER. *** The f80-floor-libcall worry
   is MOOT: clang codegen turns __builtin_{floorl,rintl,fminl,fmaxl} into `callq
   _<fn>l`, BUT cq-lowering rewrites @llvm.{floor,rint,minnum,maxnum}.f80 to
   cq_template_{floor,rint,fmin,fmax}_f80 BEFORE codegen; curated f80 bodies live in
   runtime/cq_intrinsic_templates.c and LINK. Use the __builtin_* spellings (l-suffix),
   NEVER bare floorl/rintl (the census injects the branchy s_floorl.c for the bare name
   → declines). No union/i80/Shadow/memcpy anywhere — the whole body is registers.

   *** FINITE OVER THE FINITE DOMAIN (except the true poles). *** The reduced arg is
   clamped yc = fmaxl(-π/4, fminl(y, π/4)) with the NaN-suppressing keep-set fminl/fmaxl,
   so S and C are finite for EVERY long double (±∞/NaN input → yc = ±π/4, a finite
   bound). den = 0 occurs ONLY in the odd case at y = 0 exactly (x an odd multiple of
   π/2) — the genuine pole — where num = −cos(0) = −1 ≠ 0, so tan = −1/0 = ∓∞ (the
   correct pole limit), never 0/0 → no in-domain NaN. tan is unbounded (unlike
   sin/cos), so ±∞ AT THE POLES is mathematically correct, not a defect. ±0 → +0 (no
   final copysign; a signed-zero UNSPEC edge, harmless).

   The e2e golden twin is tests/e2e/slice_branchless_tanl.c (same body, inlined at the
   slice level as `btanl`) — keep the two textually in sync. Accuracy is a trace-only
   SANITY check, not a gate: matches host libm tanl to a few ulp for |x| ≲ 5.27e7 away
   from the poles (the ratio of two faithful kernels), degrading near the poles where
   tan itself is ill-conditioned; |x| beyond that range is finite but unspecified (the
   Payne–Hanek path this body deliberately omits). Compile like the rest of the corpus
   (inject_census.py: blanket -fno-builtin; __builtin_* leaves are explicit). */
long double tanl(long double x) {
    const long double invpio2 = 6.36619772367581343076e-01L; /* 2/π, 64-bit        */
    const double      pio2_1  = 1.57079632679597125389e+00;  /* π/2, first 39 bits */
    const long double pio2_1t = -1.07463465549719416346e-12L;/* π/2 − pio2_1 (tail)*/
    const long double PIO4    = 0.78539816339744830962L;     /* π/4 clamp guard    */
    /* fdlibm ld80 k_sinl degree-8 minimax (ld80/k_sinl.c) — verbatim from sinl.c.  */
    const long double S1 = -0.166666666666666666671L;
    const double      S2 =  0.0083333333333333332,       S3 = -0.00019841269841269427,
                      S4 =  0.0000027557319223597490,    S5 = -0.000000025052108218074604,
                      S6 =  1.6059006598854211e-10,       S7 = -7.6429779983024564e-13,
                      S8 =  2.6174587166648325e-15;
    /* fdlibm ld80 k_cosl degree-7 minimax (ld80/k_cosl.c) — verbatim from sinl.c.  */
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

    /* parity in fp (no fptosi): par = fn mod 2 ∈ {0,1}. Ratio operands by a
       constant-operand fp select feeding UNCONDITIONAL weighted sums; ONE fdiv.    */
    long double par  = fn - 2.0L * __builtin_floorl(fn * 0.5L);
    long double useT = (par < 0.5L) ? 1.0L : 0.0L;             /* even quadrant → S/C */
    long double num  = useT * S + (1.0L - useT) * (-C);        /* S (even) | −C (odd) */
    long double den  = useT * C + (1.0L - useT) *   S;         /* C (even) |  S (odd) */
    return num / den;
}
