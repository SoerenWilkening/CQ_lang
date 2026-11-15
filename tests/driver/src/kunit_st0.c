/* a static helper with its own CQ_K(helper, 0): K = 0 is a K (owner ruling Q2 of 2026-11-15, CR §0) */
CQ_K(helper, 0)
__attribute__((noinline)) static int helper(int x) {
    int n = 0;
    while (x > 1) { x = (x & 1) ? 3 * x + 1 : x >> 1; n++; }
    return n;
}
int entry0(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(helper(x) + 7);
}
