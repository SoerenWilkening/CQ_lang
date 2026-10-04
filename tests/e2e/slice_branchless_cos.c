/* slice_branchless_cos.c — bd 3c6m.25 / L1: a source-injected transcendental
   (Rule 18), landed by the L1 branchless-authored body spine. A BRANCHLESS
   soft-cos is authored inline, so clang -O1 inlines it to stock reversible
   OPCODES and the taint pass lowers those (no per-fn cq_template_cos).

   openlibm's cos reduces x with Payne–Hanek, storing the split product into a
   multi-word scratch `double tx[3]` and reading it back (e_rem_pio2.c:174 —
   `tainted value stored to memory`, the L5-shadow blocker). This body replaces it
   with the SAME register-only, branchless Cody–Waite reduction and k_sin/k_cos
   kernels as slice_branchless_sin.c, exploiting cos = sin(x + π/2): adding π/2
   leaves the reduced arg y unchanged and shifts the quadrant by +1, so cos is the
   sin-weight code applied to (fn+1). All quadrant selects are `<`-against-a-
   CONSTANT (useS=(par<0.5)?1:0, sgn=(half<0.5)?1:-1) so clang -O1 keeps them
   speculatable `select`s — the atan/erf const-select-weight pattern (p119.6 kjd1
   fp-DATA select controlled-copy merge; a libm body mints no Rz/Ry). The reduced
   arg is clamped yc=fmax(-π/4,fmin(y,π/4)) with the NaN-suppressing keep-set
   fmin/fmax, so the body is FINITE for every double (±∞/NaN → finite); no
   in-domain NaN/Inf. It exercises the fp-select controlled-copy merge plus the
   rint/floor/fmin/fmax keep-set leaves.

   Domain: finite everywhere. Accurate to ≈1 ulp for |x| ≲ 1.65e6 (trace-only
   runtime, so classical ulp is a sanity check, not a gate); beyond that finite but
   unspecified (the Payne–Hanek path this body omits).

   The corpus twin is tools/library_coverage/branchless/cos.c (same body) — keep
   the two textually in sync. */
static double bcos(double x) {
    const double invpio2 = 6.36619772367581382433e-01;
    const double pio2_1   = 1.57079632673412561417e+00;
    const double pio2_1t  = 6.07710050650619224932e-11;
    const double PIO4     = 0.78539816339744830962;
    const double S1 = -1.66666666666666324348e-01, S2 =  8.33333333332248946124e-03,
                 S3 = -1.98412698298579493134e-04, S4 =  2.75573137070700676789e-06,
                 S5 = -2.50507602534068634195e-08, S6 =  1.58969099521155010221e-10;
    const double C1 =  4.16666666666666019037e-02, C2 = -1.38888888888741095749e-03,
                 C3 =  2.48015872894767294178e-05, C4 = -2.75573143513906633035e-07,
                 C5 =  2.08757232129817482790e-09, C6 = -1.13596475577881948265e-11;

    double fn = __builtin_rint(x * invpio2);
    double y  = (x - fn * pio2_1) - fn * pio2_1t;
    double yc = __builtin_fmax(-PIO4, __builtin_fmin(y, PIO4));

    double z = yc * yc, w = z * z;
    double rs = S2 + z * (S3 + z * S4) + z * w * (S5 + z * S6);
    double v  = z * yc;
    double S  = yc + v * (S1 + z * rs);
    double rc = z * (C1 + z * (C2 + z * C3)) + w * w * (C4 + z * (C5 + z * C6));
    double hz = 0.5 * z, wc = 1.0 - hz;
    double C  = wc + (((1.0 - wc) - hz) + z * rc);

    double fq   = fn + 1.0;
    double qf   = fq - 4.0 * __builtin_floor(fq * 0.25);
    double half = __builtin_floor(qf * 0.5);
    double par  = qf - 2.0 * half;
    double useS = (par  < 0.5) ? 1.0 : 0.0;
    double sgn  = (half < 0.5) ? 1.0 : -1.0;
    double mag  = useS * S + (1.0 - useS) * C;
    return sgn * mag;
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(bcos(q));
}
int main(void) { (void) slice(); return 0; }
