// M04 — P10 BREADTH: `@llvm.memcpy` in the arm.
#include <stdio.h>
#include <string.h>
int g_dst[8], g_src[8];
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { memcpy(g_dst, g_src, sizeof g_dst); m = 7; n = 2; }
  printf("%d\n", cq_measure(a) + m + n + g_dst[3]);
  return 0;
}
