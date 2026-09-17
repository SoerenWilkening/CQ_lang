// COMPOSITION ATTACK 3(c). A 4.4 merge `%out` feeds BOTH Track D's hoisted
// compare (the rail `a & 1`) AND Group 1's P2 loop-exit discharge (the same rail
// is the one anchored at the exit). `%out`-derived values become tainted only at
// the ROUND-2 `repropagateControlMerges` fixpoint, and D's
// `crossBlockCompareMintable` decides on ROUND-1 taint.
#include <CQ.h>
int main(void) {
  int q = cq_theta(0, 0.5);
  int r = cq_theta(0, 0.3);
  _Bool b = cq_theta(0, 0.4);
  int a = b ? 2 : 5;              /* 4.4 data select -> the merge %out */
  int t = a & 1;                  /* hoisted TEMPLATE rail off the %out */
  for (int i = 0; i < 2; i++) {
    if (t == 1) r = cq_theta(r, 0.9);
  }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r) + cq_measure(a);
}
