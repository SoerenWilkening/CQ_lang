struct S { int f; int g; };
int nested_pointer(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[2] = {1, 2}, b[2] = {3, 4};
    struct S s = {5, 6};
    int *tab[2] = { a, b };
    int **pp = tab + (x & 1);
    int *p = *pp;
    p[(x >> 1) & 1] = v;
    tab[(x >> 2) & 1] = &s.g;
    int *q = tab[1];
    return cq_measure(a[0] + b[1] + *q);
}
