/* tests/calls probe (cq-s2zz, CR §1.4 variadic clones, rule 20 save area): more than 6 gp actuals: the overflow area after the
 * 6 gp registers, read by -O1's va_arg loop. Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0
 * -I ../../../../CQ_spec varargs_over.c -o varargs_over.O1.ll */
#include <stdarg.h>
#include "CQ.h"
__attribute__((noinline)) static int sum8(int n, ...) {
    va_list ap;
    va_start(ap, n);
    int s = 0;
    for (int i = 0; i < 8; i++)
        s = s * 3 + va_arg(ap, int);
    va_end(ap);
    return s + n;
}
int vw_over(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(sum8(1, c, 2, x, 4, 5, x, 7, c));
}
