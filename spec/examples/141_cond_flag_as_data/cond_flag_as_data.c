int flag_as_data(int x0, double th, int k, int r0, double t) {
    int x = x0;
    cq_theta(&x, th);
    bool f = x > k;
    int r = r0;
    if (f)
        cq_theta(&r, t);                   /* the compare is the condition ... */
    return cq_measure(r) + cq_measure(f) + cq_measure(x);   /* ... and is read as data */
}
int compare_shared_by_region_and_angle(int x0, double th, int k, int r0, double p, double a, double b) {
    int x = x0;
    cq_theta(&x, th);
    if (x == k)
        cq_phi(p);                         /* one compare feeds a phase region ... */
    int r = r0;
    cq_theta(&r, x == k ? a : b);          /* ... and an angle select */
    return cq_measure(r) + cq_measure(x);
}
