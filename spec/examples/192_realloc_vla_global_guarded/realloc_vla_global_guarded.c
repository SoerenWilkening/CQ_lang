#include <stdlib.h>
/* (a) realloc of a QRAM: shrink after a quantum-index store; grow to a quantum size (§1.3, rule 16).
 * (b) a VLA written at a quantum index: a QRAM of run-time size (rule 20, §0).
 * (c) a global QRAM stored under a quantum predicate (rule 20, §1.3 _controlled). */
int realloc_shrink(unsigned k0, double tk, unsigned char v) {
    unsigned k = k0;
    cq_theta(&k, tk);
    unsigned char *a = malloc(4);
    a[k & 3] = v;                             /* cell k & 3 holds v */
    a = realloc(a, 2);                        /* shrink: cells 2, 3 stay physically present, out of range */
    unsigned char r = a[k & 1];               /* v iff k & 3 < 2 (and k & 1 == k & 3), else the indeterminate 0 */
    free(a);
    return cq_measure(r);
}
int realloc_qsize(unsigned k0, double tk, unsigned char v) {
    unsigned k = k0;
    cq_theta(&k, tk);
    unsigned char *a = malloc(2);
    a[k & 1] = v;
    a = realloc(a, (k & 3) + 2);              /* quantum size in [2, 5]: allocated at its upper bound 5 */
    a[(k & 3) + 1] = 7;                       /* a new cell when k & 3 >= 1 */
    unsigned char r = a[k & 1] + a[1];
    free(a);
    return cq_measure(r);
}
int vla_qram(unsigned x0, double tx, int y, unsigned n) {
    unsigned x = x0;
    cq_theta(&x, tx);
    int a[n];                                 /* n classical, known only at run time */
    a[x % n] = y;
    return cq_measure(a[0]);                  /* y iff x % n == 0, else the indeterminate 0 */
}
static int table[8];
int guarded_global(unsigned x0, double tx, unsigned k, unsigned i0, double ti, int y) {
    unsigned x = x0, i = i0;
    cq_theta(&x, tx);
    cq_theta(&i, ti);
    if (x > k)
        table[i & 7] = y;                     /* quantum-offset store under a quantum predicate */
    return cq_measure(table[i & 7]);
}
