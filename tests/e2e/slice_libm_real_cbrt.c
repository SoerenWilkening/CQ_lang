/* slice_libm_real_cbrt.c — bd 3c6m.14 / L6 Inc 2: the REAL openlibm cbrt
   body (s_cbrt.c, fdlibm-derived, BSD-licensed; verbatim algorithm with the
   math_private.h word macros expanded to the __builtin_memcpy idiom; the
   rounding union pun kept verbatim — clang -O1 folds both to the same
   bitcast IR). The census cell cbrt.f64: a tainted NaN/Inf guard, the
   zero-or-subnormal split whose arms build the 5-bit rough estimate by
   INTEGER DIVISION of the bit pattern (the E4 provably-safe constant-divisor
   udiv `hx/3`), a 3-incoming t-merge, then the straight-line polynomial +
   bit-rounding + Newton step over the routed base. PredMux flattens the
   nest; the shipped substrate lowers it; this slice is the LINK-layer proof
   (Rule 2). */
#include <stdint.h>

static const uint32_t
B1 = 715094163,  /* B1 = (1023-1023/3-0.03306235651)*2**20 */
B2 = 696219795;  /* B2 = (1023-1023/3-54/3-0.03306235651)*2**20 */

/* |1/cbrt(x) - p(x)| < 2**-23.5 (~[-7.93e-8, 7.929e-8]). */
static const double
P0 =  1.87595182427177009643,   /* 0x3ffe03e6, 0x0f61e692 */
P1 = -1.88497979543377169875,   /* 0xbffe28e0, 0x92f02420 */
P2 =  1.621429720105354466140,  /* 0x3ff9f160, 0x4a49d6c2 */
P3 = -0.758397934778766047437,  /* 0xbfe844cb, 0xbee751d9 */
P4 =  0.145996192886612446982;  /* 0x3fc2b000, 0xd4e4edd7 */

__attribute__((always_inline)) static inline double olm_cbrt(double x) {
    int32_t hx;
    union {
        double value;
        uint64_t bits;
    } u;
    double r, s, t = 0.0, w;
    uint32_t sign;
    uint32_t high, low;
    uint64_t bits;

    __builtin_memcpy(&bits, &x, 8);                      /* EXTRACT_WORDS */
    hx = (int32_t)(bits >> 32);
    low = (uint32_t)bits;
    sign = hx & 0x80000000;                              /* sign = sign(x) */
    hx ^= sign;
    if (hx >= 0x7ff00000) return (x + x);  /* cbrt(NaN,INF) is itself */

    if (hx < 0x00100000) {                 /* zero or subnormal? */
        if ((hx | low) == 0)
            return (x);                    /* cbrt(0) is itself */
        __builtin_memcpy(&bits, &t, 8);                  /* SET_HIGH_WORD */
        bits = (bits & 0xffffffffULL) | ((uint64_t)(uint32_t)0x43500000 << 32);
        __builtin_memcpy(&t, &bits, 8);                  /* set t = 2**54 */
        t *= x;
        __builtin_memcpy(&bits, &t, 8);                  /* GET_HIGH_WORD */
        high = (uint32_t)(bits >> 32);
        bits = (uint64_t)(uint32_t)(sign | ((high & 0x7fffffff) / 3 + B2)) << 32;
        __builtin_memcpy(&t, &bits, 8);                  /* INSERT_WORDS */
    } else {
        bits = (uint64_t)(uint32_t)(sign | (hx / 3 + B1)) << 32;
        __builtin_memcpy(&t, &bits, 8);                  /* INSERT_WORDS */
    }

    /* new cbrt to 23 bits */
    r = (t * t) * (t / x);
    t = t * ((P0 + r * (P1 + r * P2)) + ((r * r) * r) * (P3 + r * P4));

    /* round t away from zero to 23 bits */
    u.value = t;
    u.bits = (u.bits + 0x80000000) & 0xffffffffc0000000ULL;
    t = u.value;

    /* one step Newton iteration to 53 bits with error < 0.667 ulps */
    s = t * t;                  /* t*t is exact */
    r = x / s;                  /* error <= 0.5 ulps; |r| < |t| */
    w = t + t;                  /* t+t is exact */
    r = (r - t) / (w + r);      /* r-t is exact; w+r ~= 3*t */
    t = t + t * r;              /* error <= 0.5 + 0.5/3 + epsilon */

    return (t);
}

double slice(void) {
    double q = 0.5; cq_theta(&q, 0.5);
    return cq_measure(olm_cbrt(q));
}
int main(void) { (void) slice(); return 0; }
