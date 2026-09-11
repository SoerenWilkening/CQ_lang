#include <stdio.h>
__attribute__((noinline)) static int helper(int x) { return x + 1; }
int g_probe;
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5;
  if (q == 5) { a = cq_theta(a, 0.9); m = 7; }
  g_probe = helper(m);
  printf("%d\n", cq_measure(a));
  printf("g=%d\n", g_probe);
  return 0;
}
