#define _FORTIFY_SOURCE 0
#include <string.h>
int memcpy_quantum_len(unsigned x0, double th, const unsigned char *src) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[4] = {9, 9, 9, 9};
    memcpy(d, src, x & 3);                    /* quantum length: byte j copied iff j < n */
    memset(d, 0, (x >> 2) & 3);               /* quantum length: byte j cleared iff j < m */
    return cq_measure(d[0] + d[3]);
}
int memcpy_quantum_src(unsigned x0, double th, const unsigned char *s1, const unsigned char *s2) {
    unsigned x = x0;
    cq_theta(&x, th);
    unsigned char d[2] = {9, 9};
    const unsigned char *s = (x & 1) ? s1 : s2;   /* quantum source pointer: two origins */
    memcpy(d, s, x & 1 ? 2 : 1);                  /* quantum length too */
    return cq_measure(d[0] + d[1]);
}
