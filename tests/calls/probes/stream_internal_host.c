/* tests/calls probe, cq-xkmrm (rule 16): as stream_body_differs, with the module's printf `internal` (a static body, as the
   musl bundle's are after internalize). The call by name is the host boundary on both sides, so the checker turns the body
   into the host C library's printf: a clean external declaration (not dso_local, default visibility, no attribute the body
   implied), which the probe and the C oracle link against the host. The lowered program's text is compared as stdout. */
#include <stdarg.h>
typedef struct __sFILE FILE;
extern FILE *__stdoutp;
int vfprintf(FILE *restrict, const char *restrict, va_list);
int fputs(const char *restrict, FILE *restrict);
__attribute__((noinline, used)) static int printf(const char *restrict fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  fputs("B", __stdoutp); /* a body that differs from the host printf */
  int r = vfprintf(__stdoutp, fmt, ap);
  va_end(ap);
  return r;
}
int stream_internal_host(signed char x0) {
  signed char x = x0;
  cq_theta(&x, 0.3);
  if (x & 1)
    printf("%d|", x);
  printf("<%d>", x + 2);
  return cq_measure(x + 1);
}
