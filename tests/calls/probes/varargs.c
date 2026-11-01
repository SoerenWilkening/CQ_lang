/* tests/calls probe (cq-prvy, 95): a variadic clone per call-site arity, its variadic actuals spilled into the
 * x86-64 save area (a slot array of handles: the classical one promoted to a seed rail) and read back by -O1's
 * own va_arg code, here two straight-line reads. Regenerate: clang -O1 -S -emit-llvm -target
 * x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec varargs.c -o varargs.O1.ll */
#include <stdarg.h>
#include "CQ.h"
__attribute__((noinline)) static int pick(int k, ...) {
    va_list ap;
    va_start(ap, k);
    int a = va_arg(ap, int);
    int b = va_arg(ap, int);
    va_end(ap);
    return a * k + b;
}
int vprobe(int x0, double th, int c) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(pick(3, c, x) + 1);
}
