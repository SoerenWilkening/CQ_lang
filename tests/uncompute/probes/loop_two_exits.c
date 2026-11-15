/* tests/uncompute probe (cq-j9bvd, CR rules 9, 14, §0): a case-3 loop with two classical exit tests. The run flag of
 * the pre-loop templates' clean-up reads the loop's back edge; the walk enters the trip cycle through a block with one
 * predecessor and must not read false there (was: the pre-loop template of x < i leaked).
 * Regenerate: clang -O1 -S -emit-llvm -target x86_64-apple-macosx16.0.0 -I ../../../../CQ_spec loop_two_exits.c -o loop_two_exits.O1.ll */
#include "CQ.h"
int g;
int two_exits(int x0, double th, int n, int m) {
  int x = x0; cq_theta(&x, th);
  int i;
  for (i = 0; i < n; i++) {
    if (x < i) { cq_phi(0.3); break; }
    if (i == m) { g = 1; break; }
  }
  return cq_measure(x) + i;
}
