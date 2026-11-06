#include "CQ.h"
// USERCHECK f
// O1TWIN lower-switch,fix-irreducible
// O1TWINSRC computed_goto_into_loop.twin.ll
// cq-0ygtj: rule 14 "Irreducible control flow", rule 13: a computed goto entering a cycle at two blocks. fix-irreducible cannot
// read an indirectbr even in plain opt, so the C side is computed_goto_into_loop.twin.ll, clang -O1 of this file with the goto
// written as: switch ((a >> 2) & 1) { case 0: goto one; default: goto two; }
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
