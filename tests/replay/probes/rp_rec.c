/* tests/replay probe (cq-kcn5i, counters): a clone that recurses to a quantum depth, so it reads and writes rule 14's
 * activation counter, called four times with the same arguments: the record carries the counter it read and left. */
#include "CQ.h"
__attribute__((noinline)) static int chain(int n, int a) {
  if (n <= 0)
    return a;
  return a - chain(n - 1, a + 1);
}
static volatile int five = 5; /* each call reads it: four calls the compiler cannot merge, with one key */
int rp_rec(int n, double th) {
  cq_theta(&n, th);
  int s = 0;
#pragma clang loop unroll(full)
  for (int i = 0; i < 4; ++i)
    s += chain(n & 3, five);
  return cq_measure(s);
}
