struct P { int k; double v; };
double array_of_structs(unsigned x0, double th, const struct P *p) {
    unsigned x = x0;
    cq_theta(&x, th);
    return cq_measure(p[x & 7].v + p[x & 7].k);
}
