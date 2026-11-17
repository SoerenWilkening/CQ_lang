/* One bus: a host-resident alloca keeps plain instructions and classical loads; an alloca passed to host code is bus-resident. */
void ext_fill(int *p, int n);
int plain_local(int x0, double tx, int n, unsigned j) {
    int x = x0;
    cq_theta(&x, tx);
    int c[4];
    for (int i = 0; i < 4; i++)
        c[i] = n * i + 1;                     /* classical stores only, every user a load, a store or a gep */
    return cq_measure(x + c[j & 3]);          /* a plain load at a classical run-time offset: classical */
}
int overtaint_kloop(int x0, double tx, int n) {
    int x = x0;
    cq_theta(&x, tx);
    int c[4];
    ext_fill(c, n);                           /* an ordinary host call writes host bytes; c is bus-resident */
    for (int i = 0; c[i] != 0; i++)           /* the exit reads a loaded value, a rail: a K-loop */
        x += c[i];
    return cq_measure(x);
}
