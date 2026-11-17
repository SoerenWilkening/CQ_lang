static const double HALF[2] = {0.5, -0.5};     /* openlibm e_exp.c: halF[xsb], ln2HI[xsb] */
double table_f64(double x0, double th, double c) {
    double x = x0;
    cq_theta(&x, th);
    unsigned long long bits = *(unsigned long long *)&x;
    unsigned sb = (unsigned)(bits >> 63);        /* sign bit of a quantum double */
    double r = x * c + HALF[sb];                 /* table of doubles, quantum index */
    return cq_measure(r);
}
