__attribute__((noinline)) static void step(int *r, int x, int k, double t) {
    if (x > k)                                      /* the callee's own quantum condition */
        cq_theta(r, t);                             /* controlled Ry on the caller's register, through the pointer */
}
int callee_controlled_ry_in_loop(int x0, double tx, double tb, int r0, int k, double t, int n) {
    int x = x0;
    cq_theta(&x, tx);
    bool b = 0;
    cq_theta(&b, tb);
    int r = r0;
    if (b)                                          /* outer quantum condition */
        for (int i = 0; i < n; i++)                 /* classical bound inside the quantum arm */
            step(&r, x, k + i, t);                  /* fires iff b && x > k + i */
    return cq_measure(r) + cq_measure(x) + cq_measure(b);
}
