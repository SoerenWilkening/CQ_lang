#include <complex.h>
#include <math.h>
/* Rule 26 + rule 18: cabs through the complex.h entry point. musl's cabs is `hypot(creal(z), cimag(z))`; both bodies
 * (musl, MIT) are reproduced here so the -O1 IR holds what the source bundle injects: cabs lifted with mask 10 (real
 * quantum) and 11 (both quantum), hypot lifted inside it. */
static double hypot_musl(double x, double y) {
    union { double f; unsigned long long i; } ux = { x }, uy = { y }, ut;
    int ex, ey;
    double hx, lx, hy, ly, z;
    ux.i &= -1ULL >> 1; uy.i &= -1ULL >> 1;
    if (ux.i < uy.i) { ut = ux; ux = uy; uy = ut; }
    ex = ux.i >> 52; ey = uy.i >> 52;
    x = ux.f; y = uy.f;
    if (ey == 0x7ff) return y;
    if (ex == 0x7ff || uy.i == 0) return x;
    if (ex - ey > 64) return x + y;
    z = 1;
    if (ex > 0x3ff + 510) { z = 0x1p700; x *= 0x1p-700; y *= 0x1p-700; }
    else if (ey < 0x3ff - 450) { z = 0x1p-700; x *= 0x1p700; y *= 0x1p700; }
    hx = (double)(float)x; lx = x - hx; hx = hx * hx; lx = lx * (x + x - lx) + lx * lx;
    hy = (double)(float)y; ly = y - hy; hy = hy * hy; ly = ly * (y + y - ly) + ly * ly;
    return z * sqrt(ly + lx + hy + hx);
}
double cabs(double complex z) { return hypot_musl(creal(z), cimag(z)); }
double cabs_complex_h_re(double re0, double tr, double im) {
    double re = re0;
    cq_theta(&re, tr);
    double complex z = re + im * I;
    return cq_measure(cabs(z));
}
double cabs_complex_h_both(double re0, double tr, double im0, double ti) {
    double re = re0, im = im0;
    cq_theta(&re, tr);
    cq_theta(&im, ti);
    double complex z = re + im * I;
    return cq_measure(cabs(z));
}
