/* tests/calls probe, cq-tgl3i (rule 16, BACKEND_ABI §1.11): scanf and vscanf are stream calls by name, INPUT calls the host
   performs on both sides: the C program's call and the lowered program's effect entry run the host's vfscanf on the one
   input stream (ruling Q5; before it, the checker's empty input). %n stores, so the entry under the quantum predicate x & 1
   writes n through the bus (merged under the predicate); vscanf reads its pointers through the va_list of a variadic
   wrapper. */
#include <stdarg.h>
#include <stdio.h>
__attribute__((noinline)) static int rd(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vscanf(fmt, ap);
  va_end(ap);
  return r;
}
int stream_scanf(signed char x0) {
  signed char x = x0;
  cq_theta(&x, 0.3);
  int a = 7, n = -1, m = -1, r = 0;
  if (x & 1)
    r = scanf("%n%d", &n, &a);
  int r2 = rd("%n%d", &m, &a);
  return cq_measure(r * 1000 + r2 * 100 + n * 10 + m * 3 + a + x);
}
