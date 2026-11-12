/* tests/calls probe, cq-aa27m (rules 5, 6, 18; CR 556-559): vget, reached with no quantum argument (its own symbol), writes
 * memory (va_arg advances the caller's va_list), so it has no twin and its result is KEPT. The clone of h returns that rail
 * directly: a copy-out would leave it allocated beside the copy (a leak under §6 item 1). */
#include "CQ.h"
#include <stdarg.h>
__attribute__((noinline)) static int vget(va_list ap) { return va_arg(ap, int) + 1; }
static int h(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int r = vget(ap);
  va_end(ap);
  return r;
}
int kept_result_return(int x, double th) {
  cq_theta(&x, th);
  return cq_measure(h(1, x));
}
