/* cq-for9u: eight variadic ints, the last two in the overflow area: defined, in the domain */
#include <stdarg.h>
__attribute__((noinline)) int sum(int n, ...) { va_list ap; va_start(ap, n); int s = 0; for (int i = 0; i < n; i++) s += va_arg(ap, int); va_end(ap); return s; }
int f(int a, int b, double t) { int q = b; cq_theta(&q, t); int s = sum(8, q, 1, 2, 3, 4, 5, 6, a); return cq_measure(s); }
