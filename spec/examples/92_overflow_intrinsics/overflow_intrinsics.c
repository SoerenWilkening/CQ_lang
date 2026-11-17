int mul_overflow(unsigned x0, double th, unsigned c) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned r;
    int o = __builtin_mul_overflow(x, c, &r);
    return cq_measure(r) + cq_measure(o);
}
int add_overflow_qq(int x0, int y0, double tx, double ty) {
    int x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    int r;
    if (__builtin_add_overflow(x, y, &r))
        r = 0x7fffffff;
    return cq_measure(r);
}
unsigned add_sat(unsigned x0, double th, unsigned c) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned s = x + c;
    if (s < x) s = 0xffffffffu;      /* clang folds this to llvm.uadd.sat */
    return cq_measure(s);
}
