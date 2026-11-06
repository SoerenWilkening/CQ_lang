/* tests/calls probe. */
#include "CQ.h"
/* cq-00mrg: __memset_chk and __memmove_chk over quantum bytes, under a predicate too */
#include <string.h>
int chk4(int x, int n, double th) {
  char s[16], d[16];
  cq_theta(&x, th);
  memset(s, (char)x, 2 + (n & 3));
  if (x & 1) memset(s, 9, 1 + (n & 1));
  s[1] = (char)(x + 1);
  memmove(d, s, 2 + (n & 3));
  return cq_measure(d[0] + d[1]);
}
