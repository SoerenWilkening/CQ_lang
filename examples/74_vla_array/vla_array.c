int vla_array(unsigned x0, double th, int n, int c) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[n];                                   /* variable-length array: classical size */
    for (int i = 0; i < n; i++)
        a[i] = i * c;                           /* classical contents */
    return cq_measure(a[x % n]);                /* quantum index, runtime length */
}
