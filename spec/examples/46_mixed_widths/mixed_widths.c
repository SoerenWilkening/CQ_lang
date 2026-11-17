long long mixed_widths(int x0, long long y0, double tx, double ty) {
    int x = x0;
    long long y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    long long z = (long long)x * y;
    return cq_measure(z);
}
