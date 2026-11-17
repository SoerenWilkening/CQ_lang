/* e_sqrt shape: a classical-bound loop whose value arm updates three loop-carried quantum values per trip. */
int multi_carried_arm_in_loop(int ix0, double th, int r0, int n) {
    int ix = ix0;
    cq_theta(&ix, th);
    int s = 0, q = 0, r = r0;
    for (int i = 0; i < n; i++) {
        int t = s + r;
        if (t <= ix) { s = t + r; ix -= t; q += r; }
        ix += ix;
        r >>= 1;
    }
    return cq_measure(q);
}
