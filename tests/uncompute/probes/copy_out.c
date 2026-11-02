/* tests/uncompute probe (cq-4lqy; CR rule 18 twin point): a result of a clone call still live where the twin runs
 * (p.a rotated) is copied out first and the copy continues as the value; the twin zeroes both results (was: a call
 * whose results are partly kept).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec copy_out.c -o copy_out.O1.ll */
#include "CQ.h"
struct P { int a; int b; };
__attribute__((noinline)) struct P two(int x) { struct P p = {x + 1, x * 3}; return p; }
int co(int a) {          /* rule 18 twin point: p.a stays live (rotated), p.b dead: p.a is copied out */
  int x = a; cq_theta(&x, 1.0);
  struct P p = two(x);
  cq_theta(&p.a, 0.5);
  int q = p.a + p.b;
  return cq_measure(q + 1);
}
