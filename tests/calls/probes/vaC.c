/* tests/calls probe, cq-xc6us (rules 16, 19): an indirect variadic call passes the block, a quantum cell behind a classical pointer. */
#include "CQ.h"
#include <stdarg.h>
__attribute__((noinline)) static int vs(int n, va_list ap) { int s = 0; for (int i = 0; i < n; i++) s += *va_arg(ap, int *); return s; }
__attribute__((noinline)) int sum2(int n, ...) { va_list ap; va_start(ap, n); int s = vs(n, ap); va_end(ap); return s; }
int vaC(int x, int k, double th) { int a = k, b = k + 1; int (*volatile fp)(int, ...) = sum2; cq_theta(&x, th); a = x; return cq_measure(fp(2, &a, &b)); }
