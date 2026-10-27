static volatile double tiny = 1.0e-300;   /* openlibm idiom: a volatile constant that forces the inexact flag */
double volatile_global(double x0, double th, double k) {
    double x = x0;
    cq_theta(&x, th);
    double r;
    if (x < k)
        r = x * tiny;      /* read of the volatile global under a quantum condition */
    else
        r = x - tiny;
    return cq_measure(r);
}
