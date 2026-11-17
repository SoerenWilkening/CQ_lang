/* One bubble-sort pass over four quantum cells (classical i: the array is a bus-resident block, the swap is two controlled bus stores under the compare flag), then
 * a max scan over the result. */
unsigned quantum_sort_swap(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned a[4] = {x & 3, (x >> 2) & 3, (x >> 4) & 3, (x >> 6) & 3};
    for (int i = 0; i < 3; i++)
        if (a[i] > a[i + 1]) { unsigned t = a[i]; a[i] = a[i + 1]; a[i + 1] = t; }
    unsigned m = a[0];
    for (int i = 1; i < 4; i++)
        if (a[i] > m) m = a[i];
    return cq_measure(a[0] | a[1] << 2 | a[2] << 4 | a[3] << 6) | cq_measure(m) << 8;
}
