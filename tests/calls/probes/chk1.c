/* tests/calls probe, cq-00mrg (rule 22): __memcpy_chk over quantum bytes is the plain intrinsic. */
#include "CQ.h"
/* fortify __memcpy_chk with a run-time length, source holds a quantum value */
#include <string.h>
int chk1(int x, int n, double th) {
  char s[16], d[16];
  cq_theta(&x, th);
  memset(s, 0, 16);
  s[0] = (char)x;
  s[1] = (char)(x + 1);
  memcpy(d, s, 2 + (n & 3));
  return cq_measure(d[0] + d[1]);
}
