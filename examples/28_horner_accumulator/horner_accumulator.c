double horner(double x0, double th, const double *coef, int n) {
    double x = x0;
    cq_theta(&x, th);
    double s = coef[0];
    for (int i = 1; i < n; i++)
        s = s * x + coef[i];
    return cq_measure(s);
}
