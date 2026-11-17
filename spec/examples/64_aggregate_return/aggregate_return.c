struct dd { double hi, lo; };                                   /* openlibm bsdsrc b_tgamma.c: large_gam returns {double,double} */
__attribute__((noinline)) static struct dd split(double x, double c) {
    struct dd r; r.hi = x * c; r.lo = x - r.hi; return r;
}
double aggregate_return(double x0, double th, double c) {
    double x = x0;
    cq_theta(&x, th);
    struct dd r = split(x, c);
    return cq_measure(r.hi + r.lo);
}
