#include <stdarg.h>
/* A variadic root: the fixed formals follow the arrangement rule, the block is digit 0. */
long vsum(long k, long n, ...) {
  va_list ap;
  va_start(ap, n);
  long s = k;
  for (long i = 0; i < n; i++)
    s += va_arg(ap, long);
  va_end(ap);
  return s;
}
