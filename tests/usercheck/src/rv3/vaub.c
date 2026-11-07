/* cq-for9u: sum(4, q, 1) reads more variadic arguments than were passed: undefined, no sample in the domain (exit 2) */
#include <stdarg.h>
__attribute__((noinline)) int sum(int n, ...) { va_list ap; va_start(ap, n); int s = 0; for (int i = 0; i < n; i++) s += va_arg(ap, int); va_end(ap); return s; }
int f(int a, int b, double t) { int q = b; cq_theta(&q, t); int s = sum(4, q, 1); return cq_measure(s); }
