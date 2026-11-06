/* tests/calls probe. */
#include "CQ.h"
/* rules 16, 19: an address rail of a variadic function type: every candidate takes the one block */
#include <stdarg.h>
__attribute__((noinline)) int sumA(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int s = 0;
  for (int i = 0; i < n; i++) s += *va_arg(ap, int *);
  va_end(ap);
  return s;
}
__attribute__((noinline)) int sumB(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int s = 100;
  for (int i = 0; i < n; i++) s -= *va_arg(ap, int *);
  va_end(ap);
  return s;
}
int vaF(int x, int k, double th) {
  int a = k, b = k + 1;
  cq_theta(&x, th);
  int (*fp)(int, ...) = (x & 1) ? sumA : sumB;
  a = x;
  return cq_measure(fp(2, &a, &b));
}
