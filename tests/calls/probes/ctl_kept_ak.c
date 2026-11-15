/* tests/calls probe (cq-m8biu; owner ruling 2026-11-15, CR rules 14, 19): under a quantum predicate a callee is a _ctl clone
 * also when it holds a quantum-exit loop whose a_K is kept (no bound, or B > K): the predicate seeds the chain, so a_K reads 0
 * where the C program does not make the call. e1: g's loop has no bound (_ctl). e2: the call site bounds h's trip count to 3
 * <= K (clone _b3, a_K not kept), so h stays unguarded. e3: through a callee (k calls g by name).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec ctl_kept_ak.c -o ctl_kept_ak.O1.ll */
#include "CQ.h"
__attribute__((noinline)) static unsigned g(unsigned x, unsigned m) {
  unsigned s = 1, i;
  for (i = 0; x > 2; i++) { x -= 3; s = s * 5 + x; }
  return s * 16 + x + m;
}
__attribute__((noinline)) static unsigned h(unsigned n, unsigned y) {
  unsigned s = 1;
  for (unsigned i = 0; i < n; i++) s = (s * 3) ^ (y >> (s & 7));
  return s;
}
__attribute__((noinline)) static unsigned k(unsigned x, unsigned m) { return g(x, m) + 1; }
unsigned e1(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = 9;
  if (x & 64) r = g(x, m);
  return cq_measure(r);
}
unsigned e2(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = 9;
  if (x & 64) r = h(x & 3, m);
  return cq_measure(r);
}
unsigned e3(unsigned x0, double th, unsigned m) {
  unsigned x = x0; cq_theta(&x, th);
  unsigned r = 9;
  if (x & 64) r = k(x, m);
  return cq_measure(r);
}
