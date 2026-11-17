#include <stdint.h>
#include <string.h>
uint32_t high_word(double x0, double th) {
    double x = x0; cq_theta(&x, th);
    union { double d; uint32_t w[2]; } u;
    u.d = x;
    return cq_measure(u.w[1]); }
uint64_t bits_of(double x0, double th) {
    double x = x0; cq_theta(&x, th);
    uint64_t b; memcpy(&b, &x, 8);
    return cq_measure(b); }
double from_words(uint32_t h0, uint32_t l0, double th, double tl) {
    uint32_t h = h0, l = l0; cq_theta(&h, th); cq_theta(&l, tl);
    union { double d; uint32_t w[2]; } u;
    u.w[0] = l; u.w[1] = h;
    return cq_measure(u.d); }
