/* cq-xwv7r, the wide form: musl's vfwprintf works on a copy of the caller's va_list (vfwprintf.c:357). */
#include <stdarg.h>
#include <wchar.h>
#include "CQ.h"
static int after(int n, ...) {
    va_list ap;
    va_start(ap, n);
    vwprintf(L"%d\n", ap);
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
