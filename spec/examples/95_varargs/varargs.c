#include <stdarg.h>
__attribute__((noinline)) static int sum3(int n, ...) {
    va_list ap;
    va_start(ap, n);
    int s = 0;
    for (int i = 0; i < 3; i++)
        s += va_arg(ap, int);
    va_end(ap);
    return s + n;
}
int varargs(int x0, double th, int a, int b) {
    int x = x0;
    cq_theta(&x, th);
    return cq_measure(sum3(1, a, x, b));
}
