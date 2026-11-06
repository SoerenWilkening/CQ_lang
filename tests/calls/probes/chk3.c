/* tests/calls probe. */
#include "CQ.h"
/* cq-00mrg: __sprintf_chk and __strcpy_chk are the plain functions, and bind to a body the module has (rule 18) */
#include <stdarg.h>
typedef unsigned long size_t;
__attribute__((noinline)) static int sprintf(char *d, const char *f, ...) {
  va_list ap;
  va_start(ap, f);
  int v = va_arg(ap, int);
  va_end(ap);
  d[0] = f[0];
  d[1] = (char)v;
  return 2;
}
__attribute__((noinline)) static char *strcpy(char *d, const char *s) {
  d[0] = s[0];
  d[1] = s[1];
  return d;
}
extern int __sprintf_chk(char *, int, size_t, const char *, ...);
extern char *__strcpy_chk(char *, const char *, size_t);
void *volatile keep[2] = {(void *)sprintf, (void *)strcpy};
int chk3(int x, double th) {
  char d[16], e[16];
  cq_theta(&x, th);
  int n = __sprintf_chk(d, 0, 16, "%d", x & 7);
  __strcpy_chk(e, d, 16);
  return cq_measure(d[1] + e[1] + n);
}
