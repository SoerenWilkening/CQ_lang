/* slice_branchless_sin.c — bd 3c6m.44 / L1: a source-injected transcendental
   (Rule 18), landed by the L1 branchless-authored body spine. A BRANCHLESS
   soft-sin is authored inline, so clang -O1 inlines it to stock reversible
   OPCODES and the taint pass lowers those (no per-fn cq_template_sin).

   openlibm's sin reduces x with Payne–Hanek, storing the split product into a
   multi-word scratch `double tx[3]` and reading it back (e_rem_pio2.c:174 —
   `tainted value stored to memory`, the L5-shadow blocker). This body replaces it
   with a fully REGISTER-ONLY, BRANCHLESS Cody–Waite reduction: fn = rint(x·2/π),
   y = (x − fn·pio2_1) − fn·pio2_1t ∈ [-π/4,π/4] (2-term, ≈66-bit π/2 — faithful
   for |x| ≲ 1.65e6). Then fdlibm's k_sin/k_cos degree-6 kernels, and the QUADRANT
   (fn mod 4) selects ±sin(y)/±cos(y). The quadrant is derived ENTIRELY in fp
   (qf=fn−4·floor(fn/4), par=qf mod 2, half=floor(qf/2) — the hardware keep-set
   floor, no fptosi), and the answer is the UNCONDITIONAL weighted expression
   sgn·(useS·S+(1−useS)·C) with CONSTANT-operand fp selects useS=(par<0.5)?1:0 and
   sgn=(half<0.5)?1:-1 — the atan/erf const-select-weight pattern (p119.6 kjd1
   fp-DATA select controlled-copy merge; a libm body mints no Rz/Ry). The reduced
   arg is clamped yc=fmax(-π/4,fmin(y,π/4)) with the NaN-suppressing keep-set
   fmin/fmax, so the body is FINITE for every double (±∞/NaN → finite); no
   in-domain NaN/Inf. It exercises the fp-select controlled-copy merge plus the
   rint/floor/fmin/fmax keep-set leaves (and tainted floor/rint lower as reversible
   templates).

   Domain: finite everywhere; ±0 → +0 (no final copysign — a signed-zero UNSPEC
   edge, harmless). Accurate to ≈1 ulp for |x| ≲ 1.65e6 (trace-only runtime, so
   classical ulp is a sanity check, not a gate); beyond that finite but unspecified
   (the Payne–Hanek path this body omits).

   The corpus twin is tools/library_coverage/branchless/sin.c (same body) — keep
   the two textually in sync. */
static double bsin(double x) {
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

    double qf   = fn - 4.0 * __builtin_floor(fn * 0.25);
    double half = __builtin_floor(qf * 0.5);
    double par  = qf - 2.0 * half;
    double useS = (par  < 0.5) ? 1.0 : 0.0;
    double sgn  = (half < 0.5) ? 1.0 : -1.0;
    double mag  = useS * S + (1.0 - useS) * C;
    return sgn * mag;
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(bsin(q));
}
int main(void) { (void) slice(); return 0; }
