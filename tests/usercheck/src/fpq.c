/* A quantum double. */
double fpq(double a, double th) {
    double x = a;
    cq_theta(&x, th);
    return cq_measure(x * 2.0 + 1.0);
}
