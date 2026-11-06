/* tests/bus-alloc: CR rule 5: a cq_theta step inside a loop, its value stored after the loop, one gate per trip: not the
   form. In a file of its own: lowering it stops the module (Uncompute's reverse loop, cq-h0cn4), and this probe fails until that bead is closed.
   Regenerate inplace_loop.O1.ll as inplace.O1.ll. */
int g[8];
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
