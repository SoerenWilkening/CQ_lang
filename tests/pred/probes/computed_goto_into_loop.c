#include "CQ.h"
// USERCHECK f
// cq-0ygtj: rule 14 "Irreducible control flow", rule 13: a computed goto entering a cycle at two blocks.
int f(int a) {
  static void *t[2] = {&&one, &&two};
  cq_theta(&a, 1.0);
  int n = a & 3, s = 0;
  goto *t[(a >> 2) & 1];
one:
  s += 1;
two:
  s += 2;
  if (--n > 0)
    goto one;
  return cq_measure(s);
}
