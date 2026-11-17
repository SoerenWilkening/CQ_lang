/* rem_pio2 shape: an input array of quantum doubles and an output array are both passed by pointer. */
__attribute__((noinline)) static int reduce(const double *in, int n, double c, double *out) {
    double s = 0.0;
    for (int i = 0; i < n; i++)
        s = s + in[i] * c;
    out[0] = s;
    out[1] = s - in[0];
    return n + 1;
}
double array_out_param(double x0, double th, double a, double c, int n) {
    double x = x0;
    cq_theta(&x, th);
    double tx[3];
    tx[0] = x; tx[1] = x * a; tx[2] = x + a;
    double y[2];
    int m = reduce(tx, n, c, y);
    double r;
    switch (m & 3) {
    case 0:  r = y[0]; break;
    case 1:  r = y[1]; break;
    default: r = y[0] - y[1]; break;
    }
    return cq_measure(r);
}
