/* tests/calls probe, cq-8bq66 (rule 16): as stream_body_by_name, with a module fprintf that prints more than the host's.
   The call by name is the host boundary on both sides: neither the lowered program, nor the evaluator's own writes, nor
   the C oracle runs this body (BACKEND_ABI §1.11: the host C library, never a lowered symbol). */
#include <stdarg.h>
#include <stdio.h>
int fprintf(FILE *restrict f, const char *restrict fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  fputs("B", f); /* a body that differs from the host fprintf */
  int r = vfprintf(f, fmt, ap);
  va_end(ap);
  return r;
}
__attribute__((noinline)) static int show(signed char x) {
  if (x & 1)
    fprintf(stdout, "%d|", x);
  return x + 1;
}
int stream_body_differs(signed char x0) {
  signed char x = x0;
  cq_theta(&x, 0.3);
  int r = show(x);
  return cq_measure(r);
}
