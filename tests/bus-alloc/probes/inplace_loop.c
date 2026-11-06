/* tests/bus-alloc: CR rules 2, 5, 14: a cq_theta step inside a classical loop, its result read after the loop, one gate per
   trip: not the form. The rotated rail is carried out and read in place, never undone by the reverse loop (cq-h0cn4).
   Regenerate inplace_loop.O1.ll as inplace.O1.ll. */
int g[8], h[8];
__attribute__((noinline)) void put(int *p, int v) { *p = v; }
int ip_loop_theta_out(int x0, int n, double t, double u) {
    int x = cq_theta_si32(x0, t);
    put(&g[0], x);
    int y = g[0];
    int y1;
    int i = 0;
    do {
        y1 = cq_theta_si32(y, u);
    } while (++i < (n & 3));
    g[0] = y1;
    return cq_measure_si32(g[0]);
}
int ip_loop_theta_other(int x0, int n, double t, double u) {
    int x = cq_theta_si32(x0, t);
    put(&g[0], x);
    int y = g[0];
    int y1;
    int i = 0;
    do {
        y1 = cq_theta_si32(y, u);
    } while (++i < (n & 3));
    h[0] = y1;
    return cq_measure_si32(y1);
}
int ip_loop_theta_measure(int x0, int n, double t, double u) {
    int x = cq_theta_si32(x0, t);
    put(&g[0], x);
    int y = g[0];
    int y1;
    int i = 0;
    do {
        y1 = cq_theta_si32(y, u);
    } while (++i < (n & 3));
    return cq_measure_si32(y1);
}
int ip_loop_theta_after(int x0, int n, double t, double u, double w) {
    int x = cq_theta_si32(x0, t);
    put(&g[0], x);
    int y = g[0];
    int y1;
    int i = 0;
    do {
        y1 = cq_theta_si32(y, u);
    } while (++i < (n & 3));
    return cq_measure_si32(cq_theta_si32(y1, w));
}
