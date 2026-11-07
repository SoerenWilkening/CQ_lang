/* tests/loops-cutoff probe, cq-tac1 (CR rules 8, 14): a latch test `c && q` that -O1 hoisted before the loop: a trip reads it whole, so it is computed.
 * Regenerate hoisted_test.O1.ll:
 * clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec hoisted_test.c -o hoisted_test.O1.ll */
#include "CQ.h"
/* minimal a4 no-tail: select(classical,quantum) above K-loop */
int f(unsigned c) {
  _Bool b0=1,b1=1,b2=1,b3=1;
  cq_theta(&b0,1.0);cq_theta(&b1,1.0);cq_theta(&b2,1.0);cq_theta(&b3,1.0);
  unsigned v = b0|b1<<1|b2<<2|b3<<3;
  int r = 0, n = 0;
  while (v & 2) { v >>= 1; n++; if (c & 2) { if (b3) { r = 14 + n; goto C; } } }
  r = 90;
C:
  return cq_measure(r * 10 + n);
}
