#include <stdio.h>
// helper() IS a Phase-6 candidate at ROUND 1 (arg0 tainted), so the site is in
// plan6.Pending with mask {Q,C}.  The peel then makes `m` QUANTUM.  Without
// replanReseedSpecialization the frozen mask survives, declineTaintEscapes
// CARVES the site (shouldSpecialize), and specialize() clones a body reading the
// rail as an `_hl` CLASSICAL LITERAL = the bd afmv wrong unitary.
__attribute__((noinline)) static int helper(int x, int y) { return x + y; }
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; }
  int t = helper(a, m);
  printf("%d %d\n", cq_measure(t), cq_measure(q));
  return 0;
}
