/* tests/bus-alloc: §0 K2 resolution. Structural only (run_bus_alloc.py): a rail size with no bound is K2 bytes and keeps
   n > K2, and a rail length copies min(K2, B) bytes. */
#include <stdlib.h>
#include <string.h>
CQ_K2(k_used, 32);
int k_used(unsigned long n0, double th) {
    unsigned long n = n0;
    cq_theta(&n, th);
    int *a = malloc(n);
    a[0] = 1;
    return cq_measure(a[n & 1]);
}
int k_plain(unsigned long n0, double th) {
    unsigned long n = n0;
    cq_theta(&n, th);
    int *a = malloc(n);
    a[0] = 1;
    return cq_measure(a[n & 1]);
}
int k_len(unsigned long n0, double th, unsigned char *d, const unsigned char *s) {
    unsigned long n = n0;
    cq_theta(&n, th);
    memcpy(d, s, n);
    return cq_measure(d[0]);
}
int k_len_bound(unsigned long n0, double th, unsigned char *d, const unsigned char *s) {
    unsigned long n = n0;
    cq_theta(&n, th);
    memcpy(d, s, n & 7);
    return cq_measure(d[0]);
}
int k_align(unsigned long n0, double th) {
    unsigned long n = n0;
    cq_theta(&n, th);
    int *a = aligned_alloc(n, 64);
    a[0] = 1;
    return cq_measure(a[n & 1]);
}
