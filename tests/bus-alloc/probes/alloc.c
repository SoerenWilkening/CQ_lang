/* tests/bus-alloc: CR rules 16 Allocation and Deallocation, 20 Allocation, 22 and §0 K2, at the shapes no corpus example
   witnesses. Regenerate alloc.O1.ll: clang -O1 -S -emit-llvm -fno-discard-value-names is not used; see run_bus_alloc.py. */
#include <stdlib.h>
#include <string.h>

/* calloc(n, s) is the size n * s: classical */
int p_calloc(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *a = calloc(4, sizeof(int));
    a[x & 3] = v;
    return cq_measure(a[1]);
}
/* calloc at a rail count, bounded by range facts: K2 bytes, no overflow predicate */
int p_calloc_rail(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *a = calloc((x & 3) + 1, sizeof(int));
    a[0] = v;
    return cq_measure(a[x & 1]);
}
/* aligned_alloc names its alignment */
int p_aligned(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *a = aligned_alloc(64, 64);
    a[x & 1] = v;
    return cq_measure(a[1]);
}
/* a VLA at a rail count */
int p_vla_rail(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int a[(x & 3) + 1];
    a[0] = v;
    return cq_measure(a[x & 1]);
}
/* a classical run-time length, 0 included: host loops under a guard */
int p_copy_runtime(unsigned x0, double th, unsigned n0, const unsigned char *s) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[8] = {1, 2, 3, 4, 5, 6, 7, 8};
    d[x & 7] = 9;
    memcpy(d, s, n0 & 7);
    return cq_measure(d[x & 1]);
}
/* a classical length under a quantum predicate */
int p_copy_pred(unsigned x0, double th, const unsigned char *s) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[4] = {1, 2, 3, 4};
    d[x & 3] = 9;
    if (x & 16)
        memcpy(d, s, 3);
    return cq_measure(d[(x >> 1) & 3]);
}
/* a quantum length under a quantum predicate: the conjunction is each byte's one predicate */
int p_copy_len_pred(unsigned x0, double th, const unsigned char *s) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[4] = {1, 2, 3, 4};
    d[x & 3] = 9;
    if (x & 16)
        memcpy(d, s, (x >> 2) & 3);
    return cq_measure(d[(x >> 1) & 3]);
}
/* memset of a rail byte at a rail length */
int p_set_rail(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[4] = {1, 2, 3, 4};
    d[x & 3] = 9;
    memset(d, (unsigned char)(x >> 8), (x >> 4) & 3);
    return cq_measure(d[(x >> 1) & 3]);
}
/* a memset under a quantum predicate, at an address rail */
int p_set_pred(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[8] = {1, 2, 3, 4, 5, 6, 7, 8};
    d[x & 3] = 9;
    if (x & 16)
        memset(d + (x & 3), 7, 3);
    return cq_measure(d[(x >> 1) & 7]);
}
/* address rails on both sides of a copy */
int p_copy_rails(unsigned x0, double th, const unsigned char *s) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[8] = {1, 2, 3, 4, 5, 6, 7, 8};
    d[(x >> 8) & 7] = 9;
    memcpy(d + (x & 1), s + ((x >> 1) & 1), 2);
    return cq_measure(d[(x >> 1) & 3]);
}
/* memmove over an overlap: all bytes are loaded before the first store */
int p_move(unsigned x0, double th) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[4] = {1, 2, 3, 4};
    d[x & 3] = 9;
    memmove(d + 1, d, 3);
    return cq_measure(d[(x >> 2) & 3]);
}
/* a length loaded from the bus: its copy is freed between the loops, before the first store (rule 5 sentence 1) */
int p_len_loaded(unsigned x0, double th, const unsigned char *s) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char l[2] = {1, 2};
    l[x & 1] = 3;
    unsigned char d[4] = {1, 2, 3, 4};
    d[x & 3] = 9;
    memcpy(d, s, l[(x >> 1) & 1]);
    return cq_measure(d[(x >> 1) & 3]);
}
/* a realloc under a quantum predicate: unguarded, its address merged */
int p_realloc_pred(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *a = malloc(8);
    a[x & 1] = v;
    int *b = a;
    if (x & 16)
        b = realloc(a, 16);
    return cq_measure(b[1]);
}
/* free under a quantum predicate is nothing */
int p_free_pred(unsigned x0, double th, int v) {
    unsigned x = x0;
    cq_theta(&x, th);
    int *a = malloc(8);
    a[x & 1] = v;
    int r = a[1];
    if (x & 16)
        free(a);
    return cq_measure(r);
}
/* a block-scoped VLA re-entered by a classical loop: the bus-resident object drops stacksave and stackrestore */
int p_vla_loop(unsigned x0, double th, int n) {
    unsigned x = x0;
    cq_theta(&x, th);
    int r = 0;
    for (int i = 1; i < 3; i++) {
        int a[n + i];
        a[x & 1 & (n + i - 1)] = i;
        r = cq_measure(a[0]);
    }
    return r;
}
