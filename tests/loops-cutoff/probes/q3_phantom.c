/* tests/loops-cutoff probe (review R1 t2, cq-nmzv3's sibling, cq-fgo3h; rulings Q3 part 2): a site in a skipped quantum
   arm behind a classical branch inside it. The circuit runs that arm and its classical branch, so the site is credited as
   a quantum skip only where the classical condition leads to it: c is an argument (phantom) or recomputed at the quantum
   branch from c (phantom2). Where c == 0 the later `if (c)` leaves g's site by a classical condition, and no phantom
   credit covers an extra there. run_probes.py MUTANTS: the second call of g unguarded is rejected for both. (phantom's
   quantum arm is never taken, x * x & 7 is never 5; phantom2's is.)
   Regenerate q3_phantom.O1.ll:
   clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec q3_phantom.c -o q3_phantom.O1.ll */
#include "CQ.h"
__attribute__((noinline)) int g(unsigned v) { return cq_measure(v) & 0; }
int phantom(unsigned c, unsigned x0) {
  unsigned x = x0; cq_theta(&x, 0.5);
  int s = 0;
  if ((x * x & 7) == 5) { if (c) s += g(x); }
  if (c) s += g(x + 1);
  return s;
}
int phantom2(unsigned c, unsigned x0) {
  unsigned x = x0; cq_theta(&x, 0.5);
  int s = 0;
  if ((x & 7) == 5) { unsigned t = c * 3u + (c >> 1); if (t) s += g(x); }
  if (c) s += g(x + 1);
  return s;
}
