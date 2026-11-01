/* tests/calls probe (cq-09xh): a byval struct formal of a clone. The clone writes its own copy (b3: the caller
 * reads s.b after the call); the twin recomputes from the values the forward saw although the caller wrote its
 * object between the call and the twin (b_twin: r and r2 are garbage, their twins run after y).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec byval.c -o byval.O1.ll */
#include "CQ.h"
struct B { long a, b, c; };
__attribute__((noinline)) long f(struct B s, long x) { s.b += 5; return s.b * x + s.c; }
long b3(long p, long q) { long x = p; cq_theta(&x, 1.0); struct B s = { q, q + 1, 7 }; long r = f(s, x); return cq_measure(r) + s.b; }
long b_twin(long p, long q) {
  long x = p; cq_theta(&x, 1.0);
  struct B s = { q, q + 1, 7 };
  long r = f(s, x);
  s.b = q * 3;
  long r2 = f(s, x + 1);
  return cq_measure(r ^ r2) + s.b;
}
