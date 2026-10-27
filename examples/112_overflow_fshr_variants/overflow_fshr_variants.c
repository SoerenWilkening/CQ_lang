unsigned uadd_overflow_qc(unsigned x0, double th, unsigned c) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned r;
    if (__builtin_add_overflow(x, c, &r))
        r = c;                               /* not a saturation: clang keeps uadd.with.overflow */
    return cq_measure(r);
}
unsigned long usub_overflow_qq(unsigned long x0, unsigned long y0, double tx, double ty) {
    unsigned long x = x0, y = y0;
    cq_theta(&x, tx);
    cq_theta(&y, ty);
    unsigned long r;
    int o = __builtin_sub_overflow(x, y, &r);
    return cq_measure(r) + cq_measure(o);
}
unsigned rotr_qc(unsigned x0, double th, unsigned k) {
    unsigned x = x0;
    cq_theta(&x, th);
    return cq_measure(__builtin_rotateright32(x, k));
}
unsigned rotr_qq(unsigned x0, unsigned k0, double tx, double tk) {
    unsigned x = x0, k = k0;
    cq_theta(&x, tx);
    cq_theta(&k, tk);
    return cq_measure((x >> (k & 31)) | (x << ((32 - k) & 31)));   /* clang folds to fshr with a quantum amount */
}
