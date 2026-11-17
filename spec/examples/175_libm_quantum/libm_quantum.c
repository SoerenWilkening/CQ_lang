#include <math.h>
/* Rule 18 with injected libm source: transcendental functions on a quantum double. The bodies are musl's (MIT):
 * cbrt (polynomial + two Newton steps), scalbn. exp, atan2, sin, log and pow are called through the libm declarations,
 * whose bodies the compiler injects from the source bundle (not reproduced here: the O1.ll carries the libm calls or
 * the llvm math intrinsics clang emits for them, the lowering shows the lifted clone's call). */
static double cbrt_musl(double x) {
    static const unsigned B1 = 715094163, B2 = 696219795;
    static const double P0 = 1.87595182427177009643, P1 = -1.88497979543377169875, P2 = 1.621429720105354466140,
                        P3 = -0.758397934778766047437, P4 = 0.145996192886612446982;
    union { double f; unsigned long long i; } u = { x };
    double r, s, t, w;
    unsigned hx = u.i >> 32 & 0x7fffffff;
    if (hx >= 0x7ff00000) return x + x;
    if (hx < 0x00100000) {
        u.f = x * 0x1p54; hx = u.i >> 32 & 0x7fffffff;
        if (hx == 0) return x;
        hx = hx / 3 + B2;
    } else hx = hx / 3 + B1;
    u.i &= 1ULL << 63; u.i |= (unsigned long long)hx << 32; t = u.f;
    r = (t * t) * (t / x);
    t = t * ((P0 + r * (P1 + r * P2)) + ((r * r) * r) * (P3 + r * P4));
    u.f = t; u.i = (u.i + 0x80000000) & 0xffffffffc0000000ULL; t = u.f;
    s = t * t; r = x / s; w = t + t; r = (r - t) / (w + r); t = t + t * r;
    return t;
}
static double scalbn_musl(double x, int n) {
    union { double f; unsigned long long i; } u;
    double y = x;
    if (n > 1023) { y *= 0x1p1023; n -= 1023; if (n > 1023) { y *= 0x1p1023; n -= 1023; if (n > 1023) n = 1023; } }
    else if (n < -1022) { y *= 0x1p-1022 * 0x1p53; n += 1022 - 53; if (n < -1022) { y *= 0x1p-1022 * 0x1p53; n += 1022 - 53; if (n < -1022) n = -1022; } }
    u.i = (unsigned long long)(0x3ff + n) << 52;
    return y * u.f;
}
double libm_cbrt_q(double x0, double tx) { double x = x0; cq_theta(&x, tx); return cq_measure(cbrt_musl(x)); }
double libm_scalbn_qq(double x0, double tx, int n0, double tn) {
    double x = x0; int n = n0; cq_theta(&x, tx); cq_theta(&n, tn); return cq_measure(scalbn_musl(x, n)); }
double libm_exp_atan2_q(double x0, double tx, double y) {
    double x = x0; cq_theta(&x, tx); return cq_measure(exp(x) + atan2(x, y)); }
double libm_sin_log_pow_q(double x0, double tx, double y) {
    double x = x0; cq_theta(&x, tx); return cq_measure(sin(x) + log(x) + pow(x, y)); }
