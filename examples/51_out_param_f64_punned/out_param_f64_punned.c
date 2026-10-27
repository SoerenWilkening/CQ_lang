#include <stdint.h>
#include <string.h>
/* modf-shaped: the out-parameter is written in several arms, one of them by a type-punned 64-bit store. */
__attribute__((noinline)) static double split(double x, double *ip, int k, int64_t mask) {
    int64_t bits;
    memcpy(&bits, &x, 8);
    int e = (int)(bits >> 52) & 0x7ff;
    if (e < k) {                     /* |x| < 1: integral part is 0 (with x's sign) */
        int64_t z = bits & mask;     /* INSERT_WORDS(*ip, sign word, 0) */
        memcpy(ip, &z, 8);
        return x;
    }
    if (e > k + 51) {                /* no fraction */
        *ip = x;
        return x - x;
    }
    int64_t t = bits & ~(mask >> (e - k));
    double i;
    memcpy(&i, &t, 8);
    *ip = i;
    return x - i;
}
double out_param_f64_punned(double x0, double th, int k, int64_t mask) {
    double x = x0;
    cq_theta(&x, th);
    double ip;
    double f = split(x, &ip, k, mask);
    return cq_measure(f) + cq_measure(ip);
}
