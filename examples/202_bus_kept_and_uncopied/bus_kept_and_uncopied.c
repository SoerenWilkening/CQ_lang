/* One bus: a load copy whose consumers end before the next store is un-copied at once; any other copy and every store is kept. */
int bus_kept_and_uncopied(unsigned k0, double tk, int y0, double ty, double p1, double p2) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int y = y0;
    cq_theta(&y, ty);
    int a[4] = {1, 2, 3, 4};
    if (a[k & 3] > 2)                         /* load 1: its only consumer is this flag */
        cq_phi(p1);                           /* the flag and then the copy are uncomputed here, before the store */
    int t = a[(k >> 2) & 3];                  /* load 2: its consumer follows the store, so the copy is kept */
    a[k & 3] = y;                             /* a kept store: its slot, y and the address stay for the shot */
    if (t > 2)
        cq_phi(p2);
    return cq_measure(a[0]);                  /* load 3: measured */
}
