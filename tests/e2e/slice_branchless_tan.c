/* slice_branchless_tan.c — bd 3c6m.46 / L1: a source-injected transcendental
   (Rule 18), landed by the L1 branchless-authored body spine. A BRANCHLESS soft-tan
   is authored inline, so clang -O1 inlines it to stock reversible OPCODES and the
   taint pass lowers those (no per-fn cq_template_tan).

   openlibm's tan reduces x with Payne–Hanek, storing the split product into a
   multi-word scratch `double tx[3]` (e_rem_pio2.c:174 — the L5-shadow `tainted value
   stored to memory` blocker). This body REUSES the register-only, BRANCHLESS 2-term
   Cody–Waite reduction of branchless/sin.c and reconstructs tan from the SAME fdlibm
   k_sin/k_cos kernels as a RATIO — no k_tan table. tan is π-PERIODIC, so only the
   PARITY of fn = rint(x·2/π) matters: fn even → tan = S/C, fn odd → tan = −C/S
   (S=sin(y), C=cos(y), y∈[-π/4,π/4]). par = fn − 2·floor(fn/2) is derived in fp
   (floor keep-set, no fptosi), and the ratio operands are built by a CONSTANT-operand
   fp select feeding UNCONDITIONAL weighted sums with ONE division: num = useT·S +
   (1−useT)·(−C), den = useT·C + (1−useT)·S, tan = num/den — the sin/atan/erf
   const-select-weight pattern (p119.6 kjd1 fp-DATA select controlled-copy merge; a
   libm body mints no Rz/Ry). The reduced arg is clamped yc=fmax(-π/4,fmin(y,π/4))
   with the NaN-suppressing keep-set fmin/fmax, so S,C are finite for every double.

   Domain: finite except the true poles (odd multiples of π/2), where den→0 with
   num=∓1 so tan→±∞ (the correct pole limit, never 0/0 → no in-domain NaN). ±0 → +0
   (no final copysign — a signed-zero UNSPEC edge, harmless). Accurate to ≈2 ulp for
   |x| ≲ 1.65e6 away from the poles (trace-only runtime, so classical ulp is a sanity
   check, not a gate); beyond that finite but unspecified (the Payne–Hanek path this
   body omits).

   The corpus twin is tools/library_coverage/branchless/tan.c (same body) — keep the
   two textually in sync. */
static double btan(double x) {
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

    double par  = fn - 2.0 * __builtin_floor(fn * 0.5);
    double useT = (par < 0.5) ? 1.0 : 0.0;
    double num  = useT * S + (1.0 - useT) * (-C);
    double den  = useT * C + (1.0 - useT) *   S;
    return num / den;
}
double slice(void) {
    double q = cq_theta(0.5, 0.5);
    return cq_measure(btan(q));
}
int main(void) { (void) slice(); return 0; }
