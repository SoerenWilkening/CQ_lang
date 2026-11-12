/* cq-xwv7r (owner ruling 2026-11-12: the reference follows musl's source): musl's vfprintf works on a copy of the
   caller's va_list (vfprintf.c:675), so after vprintf(fmt, ap) the next va_arg(ap) is the FIRST variadic argument; the
   host's vprintf advanced it on the C side (every sample FAILed: ours y, C 100 + y). */
#include <stdarg.h>
#include <stdio.h>
#include "CQ.h"
static int after(int n, ...) {
    va_list ap;
    va_start(ap, n);
    vprintf("%d\n", ap);
    int r = va_arg(ap, int);
    va_end(ap);
    return r;
}
int f(int x0, double t) {
    int x = x0;
    cq_theta(&x, t);
    int y = x & 3;
    return cq_measure(after(2, y, 100 + y));
}
