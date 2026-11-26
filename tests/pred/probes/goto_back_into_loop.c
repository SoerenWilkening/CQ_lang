#include "CQ.h"
// USERCHECK irr_goto
// cq-jinnf: rule 14 "Irreducible control flow": a goto back into a loop body. fix-irreducible's guard has two latches, the
// exit test in one of them; a trip is a run of the guard, so a_K reads 1 where a (K+1)-th guard run begins.
int irr_goto(int x0, double th) {
  int x = x0; cq_theta(&x, th);
  int n = 0;
  if (x & 1) goto B;
  A: n += 3;
  B: n += 1; x >>= 1;
  if (x & 2) goto A;
  return n;
}
