// M05 — the P10 CONTROL: the same shape with a plain `StoreInst` in the arm.
#include <stdio.h>
int g_probe;
int main(void) {
  int q = 0, a = 0;
  q = cq_theta(q, 0.3);
  a = cq_theta(a, 0.4);
  int m = 5, n = 1;
  if (q == 5) { g_probe = 9; m = 7; n = 2; }
  printf("%d\n", cq_measure(a) + m + n + g_probe);
  return 0;
}
