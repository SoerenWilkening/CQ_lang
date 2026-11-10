/* tests/calls probe, cq-pt57w (rule 16): a stream call by name is the host boundary although the module has its body
   (as the musl bundle has fprintf's): the body is never lifted for the call, which is rule 16's format entry. */
#include <stdarg.h>
#include <stdio.h>
int fprintf(FILE *restrict f, const char *restrict fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vfprintf(f, fmt, ap);
  va_end(ap);
  return r;
}
__attribute__((noinline)) static int show(signed char x) {
  if (x & 1)
    fprintf(stdout, "%d|", x);
  return x + 1;
}
int stream_body(signed char x0) {
  signed char x = x0;
  cq_theta(&x, 0.3);
  int r = show(x);
  return cq_measure(r);
}
