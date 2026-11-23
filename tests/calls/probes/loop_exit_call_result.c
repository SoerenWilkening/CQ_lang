#include <stdarg.h>
int sink;
__attribute__((noinline)) int f(int z) { sink = z; return -1; }
__attribute__((noinline)) int ve(int k, ...) { va_list ap; va_start(ap, k); sink = va_arg(ap, int) + k; va_end(ap); return -1; }
int e(void) {
  char n = 0;
  cq_theta(&n, .5);
  unsigned x = n & 7, i = 0;
  do { x = x * 5 + 1; i++; } while ((x & 7) != 3 && i < 40);
  f(i);
  return cq_measure(i);
}
int ev(void) {
  char n = 0;
  cq_theta(&n, .5);
  unsigned x = n & 7, i = 0;
  do { x = x * 5 + 1; i++; } while ((x & 7) != 3 && i < 40);
  ve(1, i);
  return cq_measure(i);
}
