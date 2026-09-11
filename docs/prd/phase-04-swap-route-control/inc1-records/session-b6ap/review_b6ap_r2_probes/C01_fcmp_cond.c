// C01 — the region's condition is an `fcmp` (the CLONE is an FCmpInst; its
// fast-math flags and !dbg are copied by `Instruction::clone`).
#include <stdio.h>
int main(void) {
  double q = 0.0; int a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q > 2.0) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  printf("%d\n", cq_measure(a) + cq_measure(m) + cq_measure(n));
  return 0;
}
