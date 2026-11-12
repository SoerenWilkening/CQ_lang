/* tests/bus-alloc (cq-15amv): CR rule 16 Allocation by name. Compiled with -fno-builtin, as musl is: the declarations of
   malloc, calloc, realloc and free carry no allockind, so the call is the allocation by its rule-16 name alone. Its
   result is __cq_alloc's classical address under a rail size, also for the taint (the compare with NULL is classical).
   Regenerate: clang -O1 -fno-builtin -include CQ.h -S -emit-llvm (see run_bus_alloc.py). */
#include <stdlib.h>

/* a rail count */
int n_calloc_count(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *a = calloc((x & 3) + 1, sizeof(int));
    if (a == NULL)
        return cq_measure(-1);
    a[x & 3] = v;
    int r = a[0] + a[x & 3];
    free(a);
    return cq_measure(r);
}
/* a rail element size */
int n_calloc_size(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char *a = calloc(2, (x & 7) + 1);
    if (a == NULL)
        return cq_measure(-1);
    a[x & 1] = (unsigned char)v;
    int r = a[0];
    free(a);
    return cq_measure(r);
}
/* both rails */
int n_calloc_both(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char *a = calloc((x & 3) + 1, ((x >> 2) & 3) + 1);
    if (a == NULL)
        return cq_measure(-1);
    a[0] = (unsigned char)v;
    int r = a[0] + a[x & 3];
    free(a);
    return cq_measure(r);
}
/* a rail count with no bound from range facts: K2 bytes and the kept n > K2 */
int n_calloc_wide(unsigned short x0, double th, int v) {
    unsigned short x = x0;
    cq_theta(&x, th);
    unsigned char *a = calloc(x, 1);
    if (a == NULL)
        return cq_measure(-1);
    if (x)
        a[0] = (unsigned char)v;
    int r = x ? a[0] : -2;
    free(a);
    return cq_measure(r);
}
/* malloc at a rail size (a measured value that is classical here is cq-yt5lz, a checker bug) */
int n_malloc(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *a = malloc(((x & 3) + 1) * sizeof(int));
    if (a == NULL)
        return cq_measure(-1);
    a[x & 3] = v + (int)x;
    int r = a[x & 3];
    free(a);
    return cq_measure(r);
}
/* realloc to a rail size */
int n_realloc(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *a = malloc(sizeof(int));
    if (a == NULL)
        return cq_measure(-1);
    a[0] = v;
    int *b = realloc(a, ((x & 3) + 1) * sizeof(int));
    if (b == NULL)
        return cq_measure(-1);
    b[x & 3] = 1;
    int r = b[0] + b[x & 3];
    free(b);
    return cq_measure(r);
}
