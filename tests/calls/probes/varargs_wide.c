/* tests/calls probe (cq-s2zz, CR §1.4 variadic clones, rule 20 save area): the x86-64 SysV layout of the
 * actuals as LLVM's calling convention places them: gp registers then the overflow area (more than 6 gp
 * arguments), xmm slots for doubles, the overflow area for an x86_fp80, a named pointer parameter, a classical
 * pointer actual. Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../../../../CQ_spec varargs_wide.c -o varargs_wide.O1.ll */
#include <stdarg.h>
#include "CQ.h"
__attribute__((noinline)) static double fsum(int *p, ...) {
    va_list ap;
    va_start(ap, p);
    double a = va_arg(ap, double);
    long b = va_arg(ap, long);
    double c = va_arg(ap, double);
    va_end(ap);
    return a + (double)b * c + *p;
}
double vw_fp(double d0, double th, long c) {
    double d = d0;
    cq_theta(&d, th);
    int k = 3;
    return cq_measure(fsum(&k, d, c, 2.5));
}
__attribute__((noinline)) static long double lsum(int n, ...) {
    va_list ap;
    va_start(ap, n);
    long double a = va_arg(ap, long double);
    int b = va_arg(ap, int);
    va_end(ap);
    return a + b + n;
}
long double vw_ld(int x0, double th, long double c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(lsum(2, c, x));
}
__attribute__((noinline)) static int pptr(int x, ...) {
    va_list ap;
    va_start(ap, x);
    const int *t = va_arg(ap, const int *);
    int n = va_arg(ap, int);
    va_end(ap);
    return t[n & 3] + x;
}
static const int tab[4] = {5, 7, 11, 13};
int vw_ptr(int x0, double th, int k) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(pptr(x, tab, k));
}
