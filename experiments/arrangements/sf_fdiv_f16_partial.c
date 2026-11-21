_Float16 cqsf_fdiv_f16(_Float16, _Float16);
unsigned short f(unsigned short qa, int c) {
    cq_theta(&qa, 0.3);
    union { _Float16 h; unsigned short u; } a, b, r;
    a.u = qa; b.u = (unsigned short)c;
    r.h = cqsf_fdiv_f16(a.h, b.h);
    return cq_measure(r.u);
}
