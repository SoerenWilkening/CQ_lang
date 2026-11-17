int measure_one_of_two(int x0, int y0, double tx, double ty, int c) {
    int x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    int s = x + y;
    int mx = cq_measure(x);
    int t = s * c;
    return cq_measure(t) + mx;
}
