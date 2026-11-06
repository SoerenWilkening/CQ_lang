#include "CQ.h"
/* cq-fm-f1 (CR rules 18, 19): an own symbol that returns a callee's result as it stands (musl strcoll over strcmp). The caller's
   twin of the outer one recomputes through outer's _pure clone, where the inner result is garbage: inner needs its twin too. */
__attribute__((noinline)) static int inner(const char *a) { return a[0] + a[1]; }
__attribute__((noinline)) static int mid(const char *a) { return inner(a); }
__attribute__((noinline)) static int outer(const char *a) { return mid(a); }
int orc(char x) {
  char b[2] = {0, 3};
  b[0] = x;
  cq_theta(&b[0], 0.3);
  int r = outer(b) + 1;
  return cq_measure(r);
}
