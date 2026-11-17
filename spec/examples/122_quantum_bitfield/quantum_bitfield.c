struct fields { unsigned a : 3, b : 5, c : 24; };        /* one 32-bit storage unit: a = bits 0-2, b = 3-7, c = 8-31 */
int quantum_bitfield(unsigned w0, double th, unsigned v, unsigned k, double ph) {
    unsigned w = w0;
    cq_theta(&w, th);                                    /* the whole storage unit is quantum */
    struct fields f;
    __builtin_memcpy(&f, &w, sizeof f);                  /* view the word as bit-fields */
    f.b = f.a + v;                                       /* read one field, write another: read-modify-write of the word */
    if (f.b > k)                                         /* quantum condition reading the field just written */
        cq_phi(ph);
    __builtin_memcpy(&w, &f, sizeof f);
    return cq_measure(w);                                /* the updated word is measured */
}
__attribute__((noinline)) static void bump_c(struct fields *p, unsigned d) {
    p->c += d;                                           /* RMW of the storage unit through a pointer, in a callee */
}
int bitfield_through_pointer(unsigned w0, double th, unsigned d, double ph) {
    struct fields f;
    unsigned w = w0;
    cq_theta(&w, th);
    __builtin_memcpy(&f, &w, sizeof f);
    bump_c(&f, d);                                       /* the struct stays in memory: a slot passed to a lifted call */
    if (f.a == 5)                                        /* quantum condition on a field the callee did not touch */
        cq_phi(ph);
    return cq_measure(f.c);
}
