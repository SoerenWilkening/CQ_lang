/* defines f, CQ_K(f, 0): K = 0 is a K (owner ruling Q2 of 2026-11-15, CR §0), the loop runs no trip */
CQ_K(f, 0)
int f(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    int n = 0;
    while (x > 1) { x = (x & 1) ? 3 * x + 1 : x >> 1; n++; }
    return cq_measure(n);
}
