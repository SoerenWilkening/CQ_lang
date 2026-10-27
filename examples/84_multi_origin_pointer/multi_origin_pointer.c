int ptr_select_store(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[2] = {1, 2}, b[2] = {3, 4};
    int *p = (x & 1) ? a : b;            /* a pointer selected by a quantum bit: two origins */
    if (x > 5)                           /* stored through later, under an independent quantum condition */
        p[(x >> 1) & 1] = v;
    return cq_measure(a[0] + b[1]);
}
