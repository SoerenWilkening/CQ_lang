// M01 — P10 BREADTH: the arm writes memory through `@llvm.memset`, which is a
// CallInst, NOT a `StoreInst`, so `armWritesMemory` does not see it.
#include <stdio.h>
#include <string.h>
int main(void) {
  int q = 0, a = 0;
  int buf[8];
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { memset(buf, 0, sizeof buf); m = 7; n = 2; }
  printf("%d %d %d %d\n", cq_measure(a), m, n, buf[3]);
  return 0;
}
