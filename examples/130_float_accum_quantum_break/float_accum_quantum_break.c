int float_accum_break(double x0, double th, const double *c, int n, double lim, double tr) {
    double x = x0;
    cq_theta(&x, th);
    double acc = 0.0;
    for (int i = 0; i < n; i++) {        /* classical bound */
        acc += c[i] * x;                 /* loop-carried quantum double (fmuladd) */
        if (acc > lim)                   /* quantum break */
            break;
    }
    bool r = 0;
    if (acc > 2.0 * lim)                 /* controlled Ry on the final accumulator */
        cq_theta(&r, tr);
    return cq_measure(r) + (cq_measure(acc) > 0.0);
}
