#include <stdlib.h>
#include <stdint.h>
/* free(a) of a QRAM heap block (rule 20: a store at a quantum index) ends its lifetime (rule 16). */
int free_uncond(unsigned k0, double tk, unsigned char v) {
    unsigned k = k0;
    cq_theta(&k, tk);
    unsigned char *a = malloc(4);
    a[k & 3] = v;                             /* quantum-offset store: a is a QRAM */
    unsigned char r = a[1];                   /* fixed-index read */
    a = realloc(a, 6);                        /* classical new size: the same object */
    a[5] = 2;                                 /* store into a new cell */
    r += a[k % 6];                            /* read at a quantum index */
    free(a);                                  /* unconditional: clean-up and qram_free here */
    unsigned s = k * 3;                       /* work after the free */
    return cq_measure(r) + cq_measure(s);
}
int free_classical_cond(unsigned k0, double tk, unsigned char v, int c) {
    unsigned k = k0;
    cq_theta(&k, tk);
    unsigned char *a = malloc(4);
    a[k & 3] = v;
    unsigned char r = a[1];
    a = realloc(a, 6);
    a[5] = 2;
    r += a[k % 6];
    if (c)
        free(a);                              /* classical condition: clean-up and qram_free on this path */
    unsigned s = k * 3;
    return cq_measure(r) + cq_measure(s);     /* c == 0: C leaks a; its lifetime ends with the scope */
}
int free_entangled(unsigned k0, double tk, unsigned char x0, double tx, double t2) {
    unsigned k = k0;
    cq_theta(&k, tk);
    unsigned char x = x0;
    cq_theta(&x, tx);
    unsigned char *a = malloc(4);
    a[k & 3] = x;                             /* quantum-offset store of the register x */
    cq_theta(&x, t2);                         /* x rotated while the cell still holds its old value */
    a[0] = 1;                                 /* a later fixed-index store */
    unsigned char r = a[1] + a[0];            /* reads after the rotation */
    free(a);                                  /* the first store cannot be popped: the block stays allocated */
    return cq_measure(r);
}
int qram_ptr_addr(unsigned k0, double tk, const int *other) {
    unsigned k = k0;
    cq_theta(&k, tk);
    int *a = malloc(4 * sizeof(int));
    a[k & 3] = 5;                             /* quantum-offset store: a is a QRAM */
    int *p = a + ((k >> 1) & 3);              /* fat pointer into a at a quantum idx */
    int eq = p == other;                      /* address compare against a host object: false on every branch */
    int lt = p < a + 2;                       /* order compare within the QRAM object */
    long d = (long)((uintptr_t)p - (uintptr_t)a);   /* ptrtoint arithmetic: 4 * idx, independent of the base */
    int r = a[1];
    free(a);
    return cq_measure(eq) + cq_measure(lt) + cq_measure(d) + cq_measure(r);
}
