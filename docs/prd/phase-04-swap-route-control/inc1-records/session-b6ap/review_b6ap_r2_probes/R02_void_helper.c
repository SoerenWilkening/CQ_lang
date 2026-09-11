// R02 — the helper returns VOID (nothing to specialize a result from).
#include <stdio.h>
int g_probe;
__attribute__((noinline)) static void helper(int x) { g_probe = x + 1; }
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3); a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; n = 2; }
  helper(m);
  printf("%d %d %d\n", cq_measure(a), cq_measure(n), g_probe);
  return 0;
}
