/* a static helper with its own CQ_K(helper, 3) */
CQ_K(helper, 3)
__attribute__((noinline)) static int helper(int x) {
    int n = 0;
    while (x > 1) { x = (x & 1) ? 3 * x + 1 : x >> 1; n++; }
    return n;
}
int entry3(int x0, double th) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(helper(x) + 3);
}
