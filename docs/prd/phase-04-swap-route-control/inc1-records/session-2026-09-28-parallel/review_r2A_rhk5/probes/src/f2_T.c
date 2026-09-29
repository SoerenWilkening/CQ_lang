#include <stdlib.h>
/* r2A f2 — TWO (b') rails p, w in one component with u = p + w; p's clone BEFORE the
   Ry, w's clone AFTER. Layer (1) tries only all-in / all-out. */
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q & 3;
  int w = q * 5;
  int u = p ^ w;
  if (u == 10) cq_phi(3.14159);
  int s1 = (p + 1);
  int q2 = cq_theta(q, 0.7);
  int s2 = (w + 1);
  return cq_measure(s1) + cq_measure(s2) + cq_measure(q2);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
