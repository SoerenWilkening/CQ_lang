/* tests/spine probe (cq-4ka4, CR §1.2 and §2: "a commutative op puts the handle first"): sadd_sat with a classical
 * first operand is spelled _hl with its operands swapped, as uadd_sat is; never _lh. */
#include "CQ.h"
__attribute__((noinline)) static int g(int c, int q) {
  return __builtin_elementwise_add_sat(c, q);
}
int sat(int a) {
  int q = 0;
  cq_theta(&q, 1.0);
  return cq_measure(g(a, q));
}
