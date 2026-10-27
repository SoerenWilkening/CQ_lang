/* ilogb shape: two normalization loops, each inside a quantum arm, feeding one merge with constant arms. */
int loop_in_arm_multi_exit(int hx0, int lx0, double t1, double t2, int k1, int c) {
    int hx = hx0, lx = lx0;
    cq_theta(&hx, t1);
    cq_theta(&lx, t2);
    int e;
    if (hx < k1) {
        if (hx == 0) {
            e = -1043;
            for (; lx > 0; lx <<= 1) e--;
        } else {
            e = -1022;
            for (hx <<= 11; hx > 0; hx <<= 1) e--;
        }
    } else {
        e = (hx >> 20) - c;
    }
    return cq_measure(e);
}
