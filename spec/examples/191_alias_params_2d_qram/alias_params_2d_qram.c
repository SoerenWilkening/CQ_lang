/* (a) Aliasing pointer parameters into one QRAM object (rules 18, 20, 21). (b) A 2-D local QRAM (rule 20). */
__attribute__((noinline)) static void addto(int *p, int *q) { *p += *q; }
int alias_params(unsigned x0, double tx, int a0, int a1) {
    unsigned x = x0;
    cq_theta(&x, tx);
    int a[2] = {a0, a1};
    addto(a, a + (x & 1));                    /* q == p when x & 1 == 0: *p doubles; else a[0] += a[1] */
    return cq_measure(a[0]);
}
int qram_2d(unsigned r0, double tr, unsigned c0, double tc, int v) {
    unsigned r = r0, c = c0;
    cq_theta(&r, tr);
    cq_theta(&c, tc);
    int g[4][4] = {0};
    g[r & 3][c & 3] = v;                      /* quantum-offset store: g is a QRAM, cell (r & 3) * 4 + (c & 3) */
    return cq_measure(g[1][2] + g[r & 3][0]);
}
