/* tests/loops-cutoff probe, cq-anzut (CR rule 14): `while (q && m < N)` with a quantum break: the mixed header test leaves classically into an arm that
 * computes a value.
 * Regenerate while_mixed.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec while_mixed.c -o while_mixed.O1.ll */
#include "CQ.h"
int f(void) {
  _Bool b1=1,b3=1;
  cq_theta(&b1,1.0);cq_theta(&b3,1.0);
  int m = 0, r;
  while (b3 && m < 2) { m++; if (b1) { r = 21; goto C; } }
  r = 30 + m;
C:
  return cq_measure(r);
}
