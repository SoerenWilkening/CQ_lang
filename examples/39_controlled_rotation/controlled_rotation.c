int controlled_rotation(int x0, double t1, int k, int r0, double t2) {
    int x = x0;
    cq_theta(&x, t1);
    int r = r0;
    if (x > k)
        cq_theta(&r, t2);
    return cq_measure(r) + cq_measure(x);
}
int controlled_rotation_ifelse(int x0, double t1, int k, int r0, double ta, double tb) {
    int x = x0;
    cq_theta(&x, t1);
    int r = r0;
    if (x > k)
        cq_theta(&r, ta);
    else
        cq_theta(&r, tb);
    return cq_measure(r) + cq_measure(x);
}
