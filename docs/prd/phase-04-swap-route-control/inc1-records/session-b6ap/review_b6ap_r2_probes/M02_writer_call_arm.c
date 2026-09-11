// M02 — P10 BREADTH: the arm calls a visible function that STORES to a global.
#include <stdio.h>
int g_probe = 0;
__attribute__((noinline)) static void writer(int v) { g_probe = v; }
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { writer(9); m = 7; n = 2; }
  printf("%d %d %d %d\n", cq_measure(a), m, n, g_probe);
  return 0;
}
