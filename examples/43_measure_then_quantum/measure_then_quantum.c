int measure_then_quantum(int x0, int y0, double tx, double ty, int k, double phi) {
    int x = x0, y = y0;
    cq_theta(&x, tx);
    int mx = cq_measure(x);
    cq_theta(&y, ty);
    if (mx > k)
        y = y + mx;
    if (y == k)
        cq_phi(phi);
    return cq_measure(y);
}
