/* slice_branchless_pow_cq.c — bd 3c6m.40 / 3c6m.48: the (c,q) taint mask of pow.
   Each mask is a DISTINCT unitary (3c6m.48). slice_branchless_pow.c pins (q,c) [x=q
   tainted, y=0.5 const -> pow(q,0.5)=sqrt(q), the FULL log2(q) closure]; THIS slice
   pins (c,q): x = 0.5 CONSTANT, y = q TAINTED -> pow(0.5,q) = 2^(-q). log2(0.5)
   const-folds to -1.0 (x classical), so the log2 closure evaporates and the tainted
   path is exp2(q * -1) -> exp(-q*ln2) — the exp round-bias select only. Same
   blog2/bexp2/bexp/bpow bodies (== corpus twins) — keep textually in sync. A PURE
   value-embedding (0 controlled rotations, 1 flag mint/strip/free, 1 ry + 1 measure)
   backing the census `combinations` entry. Domain/accuracy identical to
   slice_branchless_pow.c. */

/* the branchless exp kernel, inlined (== tools/library_coverage/branchless/exp.c) */
static double bexp(double x) {
    double xn   = x * 1.4426950408889634;                 /* x / ln2                        */
    double half = (xn < 0.0) ? -0.5 : 0.5;                /* branchless round bias (select) */
    int    n    = (int)(xn + half);                       /* fptosi on select-derived fp    */
    double r    = x - (double)n * 0.6931471805599453;     /* reduced arg (sitofp back)      */
    double p    = 1.0 + r*(1.0 + r*(0.5 + r*(0.1666666666666
                     + r*(0.0416666666 + r*0.008333333)))); /* Horner exp(r) on reduced range */
    long long bits = (long long)(n + 1023) << 52;         /* 2^n exponent field             */
    double scale;
    __builtin_memcpy(&scale, &bits, 8);                   /* bitcast i64->f64 (INSERT_WORDS) */
    return p * scale;
}

/* the branchless exp2 kernel, inlined (== tools/library_coverage/branchless/exp2.c) */
static double bexp2(double x) {
    return bexp(x * 0.69314718055994530942);              /* 2^x = e^(x·ln2)                */
}

/* the branchless log2 kernel, inlined (== tools/library_coverage/branchless/log2.c) */
static double blog2(double x) {
    long long bits;
    __builtin_memcpy(&bits, &x, 8);                     /* bitcast f64->i64 (EXTRACT_WORDS) */
    bits += 0x3FF0000000000000LL - 0x3FE6A09E667F3BCDLL; /* shift boundary to sqrt(2)/2      */
    int k = (int)(bits >> 52) - 1023;                   /* exponent, sqrt(2)-centered        */
    long long mbits = (bits & 0x000FFFFFFFFFFFFFLL) + 0x3FE6A09E667F3BCDLL;
    double m;
    __builtin_memcpy(&m, &mbits, 8);                    /* bitcast i64->f64: m in [√2/2,√2)  */
    double f  = m - 1.0;
    double s  = f / (2.0 + f);                          /* k_log1p(f) = s*(hfsq+R)           */
    double z  = s * s;
    double w  = z * z;
    double t1 = w * (3.999999999940941908e-01           /* musl/openlibm Lg2/Lg4/Lg6         */
              + w * (2.222219843214978396e-01
              + w *  1.531383769920937332e-01));
    double t2 = z * (6.666666666666735130e-01           /* Lg1/Lg3/Lg5/Lg7                   */
              + w * (2.857142874366239149e-01
              + w * (1.818357216161805012e-01
              + w *  1.479819860511658591e-01)));
    double R    = t2 + t1;
    double hfsq = 0.5 * f * f;
    double r    = s * (hfsq + R);
    /* openlibm e_log2.c combining/scaling in extra precision (VERBATIM):      */
    double hi = f - hfsq;
    long long hibits;
    __builtin_memcpy(&hibits, &hi, 8);
    hibits &= 0xFFFFFFFF00000000LL;                     /* SET_LOW_WORD(hi, 0)               */
    __builtin_memcpy(&hi, &hibits, 8);
    double lo = (f - hi) - hfsq + r;
    double y      = (double)k;                          /* sitofp i32->f64                   */
    double val_hi = hi * 1.44269504072144627571e+00;    /* ivln2hi                           */
    double val_lo = (lo + hi) * 1.67517131648865118353e-10  /* ivln2lo                       */
                  + lo * 1.44269504072144627571e+00;
    double ww = y + val_hi;                             /* Dekker two-sum of k + val_hi      */
    val_lo += (y - ww) + val_hi;
    val_hi = ww;
    return val_lo + val_hi;
}

static double bpow(double x, double y) {
    return bexp2(y * blog2(x));                           /* x^y = 2^(y·log2 x)      */
}
double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(bpow(0.5, q));                      /* (c,q): x const, y tainted */
}
int main(void) { (void) slice(); return 0; }
