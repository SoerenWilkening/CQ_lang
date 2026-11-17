unsigned fshl_qq(unsigned a0, unsigned b0, double ta, double tb) {
    unsigned a = a0, b = b0; cq_theta(&a, ta); cq_theta(&b, tb);
    return cq_measure((a << 1) | (b >> 31)); }                      /* openlibm e_fmod.c: hx = hx+hx+(lx>>31) */
unsigned rotl_qc(unsigned x0, double th, unsigned k) {
    unsigned x = x0; cq_theta(&x, th);
    return cq_measure((x << k) | (x >> (32 - k))); }                 /* rotate by a classical amount */
int clz_q(unsigned x0, double th) {
    unsigned x = x0; cq_theta(&x, th);
    return cq_measure(__builtin_clz(x)); }                           /* e_sqrt.c normalisation count */
int popcount_q(unsigned x0, double th, unsigned c) {
    unsigned x = x0; cq_theta(&x, th);
    return cq_measure(__builtin_popcount(x & c)); }                  /* Deutsch-Jozsa parity oracle */
int smax_qc(int x0, double th, int c) {
    int x = x0; cq_theta(&x, th);
    return cq_measure(x > c ? x : c); }                              /* k_rem_pio2.c */
unsigned umax_qq(unsigned x0, unsigned y0, double tx, double ty) {
    unsigned x = x0, y = y0; cq_theta(&x, tx); cq_theta(&y, ty);
    return cq_measure(x > y ? x : y); }                              /* e_hypot.c */
int abs_q(int x0, double th) {
    int x = x0; cq_theta(&x, th);
    return cq_measure(__builtin_abs(x)); }                           /* ld80 e_powl.c */
unsigned fptoui_q(double x0, double th) {
    double x = x0; cq_theta(&x, th);
    return cq_measure((unsigned)x); }                                /* s_erf.c, e_lgamma_r.c */
double same_operand_twice(double x0, double th, double p) {
    double x = x0; cq_theta(&x, th);
    return cq_measure(((long double)x * p) / ((long double)x * p)); }  /* e_remainder.c NaN idiom: widen, one rail used twice */
