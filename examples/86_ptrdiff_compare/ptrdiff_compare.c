long ptrdiff_q(unsigned x0, double th, int *a) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *p = a + (x & 3);
    int *q = a + ((x >> 2) & 3);
    return cq_measure(q - p);
}
int ptr_less(unsigned x0, double th, int *a, int *b) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *p = ((x & 1) ? a : b) + ((x >> 1) & 3);
    int *q = a + ((x >> 3) & 3);
    return cq_measure(p < q);
}
int ptr_eq_two_objects(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[4] = {0, 0, 0, 0}, b[4] = {0, 0, 0, 0};
    int *p = ((x & 1) ? a : b) + ((x >> 1) & 3);
    int *q = a + ((x >> 3) & 3);
    return cq_measure(p == q);
}
