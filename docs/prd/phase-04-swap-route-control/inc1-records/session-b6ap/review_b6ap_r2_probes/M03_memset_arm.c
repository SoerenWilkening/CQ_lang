// M03 — P10 BREADTH, clean: the arm writes memory via `@llvm.memset` (a CallInst,
// not a StoreInst). `armWritesMemory` cannot see it.
#include <stdio.h>
#include <string.h>
int g_buf[8];
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { memset(g_buf, 0, sizeof g_buf); m = 7; n = 2; }
  printf("%d\n", cq_measure(a) + m + n + g_buf[3]);
  return 0;
}
