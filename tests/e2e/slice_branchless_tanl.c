/* slice_branchless_tanl.c — bd 20xt.9 / the ld80 (x86_fp80) branchless-leaf e2e twin
   of tools/library_coverage/branchless/tanl.c. An AUTHORED branchless soft-tanl is
   inlined here as `btanl`, so clang -O1 inlines it to stock reversible OPCODES and the
   taint pass lowers those (no per-fn cq_template_tanl). The missing trio leaf beside
   slice_branchless_{sinl,cosl}.c. DISJOINT hybrid/authored-leaf provenance, NEVER
   quoted alongside the real-openlibm goldens; verification is e2e-golden-only and the
   census cell tanl.f80 stays declined (NO census delta). Bennett-gated: tan is backed
   by Bennett's `soft_tan`.

   openlibm's tanl reduces x with the full __kernel_rem_pio2 Payne–Hanek reduction
   (alloca [20 x i32]/[20 x double] + tainted dynamic-index stores in bounded loops —
   Bennett MUX-EXCH, ROADMAP 7.5 post-freeze). This body replaces it with a fully
   REGISTER-ONLY, BRANCHLESS 2-term Cody–Waite reduction (fn = rintl(x·2/π), y ∈
   [-π/4,π/4]) reusing sinl.c's PROVEN reduction constants + k_sinl/k_cosl kernels.
   tan is π-periodic, so ONLY fn mod 2 matters: even → tan = S/C, odd → -C/S. It is
   reconstructed as a RATIO of the SAME k_sinl/k_cosl kernels — NOT openlibm's
   ld80/k_tanl.c polynomial, which is branchy (an `if |x|>=0.67434` pio4-fold) and
   faithful only on the narrower [-0.67434,0.67434]; the ratio is faithful across the
   whole reduced [-π/4,π/4] and branchless (see branchless/tanl.c for the full
   derivation + design note; recorded on bd 20xt.9). par = fn − 2·floorl(fn/2) ∈ {0,1}
   is derived ENTIRELY in fp (keep-set floorl, no fptosi); useT=(par<0.5)?1:0 is a
   CONSTANT-operand fp select (kjd1 cqrt_copy_f80_controlled) feeding UNCONDITIONAL
   weighted sums num=useT·S+(1−useT)·(−C), den=useT·C+(1−useT)·S and ONE unconditional
   fdiv num/den (cq_template_fdiv_f80 QQ). __builtin_{rintl,floorl,fminl,fmaxl} are the
   l-suffix keep-set leaves (@llvm.<fn>.f80 → cq_template_<fn>_f80 before codegen; never
   bare floorl). No union/i80/Shadow/memcpy — pure registers.

   FINITE over the finite domain except the true poles: yc is clamped to [-π/4,π/4] by
   fminl/fmaxl, so S,C finite for every long double; den=0 only in the odd case at y=0
   (an odd multiple of π/2 — the genuine pole) where num=−1≠0 → tan=∓∞ (correct pole),
   never 0/0. Accuracy is a trace-only SANITY check, not a gate (runtime is trace-only;
   tanl(0.5) is finite). Keep this body textually in sync with branchless/tanl.c. */
static long double btanl(long double x) {
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
long double slice(void) {
    long double q = cq_theta(0.5L, 0.5);
    return cq_measure(btanl(q));
}
int main(void) { (void) slice(); return 0; }
