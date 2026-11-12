/* tests/calls probe, cq-f0rb6 (rules 16, 19, 22): an own symbol (vget, reached with no quantum argument) reads its quantum
 * input only through memory: a va_copy of the caller's bus-resident va_list. va_copy is memcpy(d, s, 24) (rule 16, 109),
 * so a bus copy here, never the host intrinsic. */
#include "CQ.h"
#include <stdarg.h>
__attribute__((noinline)) static int vget(va_list ap) {
  va_list aq;
  va_copy(aq, ap);
  int v = va_arg(aq, int);
  va_end(aq);
  return v + 1;
}
static int h(int n, ...) {
  va_list ap;
  va_start(ap, n);
  int r = cq_measure(vget(ap));
  va_end(ap);
  return r;
}
int va_copy_own(int x, double th) {
  cq_theta(&x, th);
  return h(1, x);
}
