#include <stdlib.h>
/* r2A f1 — one (b') rail p read by TWO clone calls, one BEFORE and one AFTER the Ry on q */
int h(int a, int k);
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q & 3;
  int u = p + q;
  if (u == 10) cq_phi(3.14159);
  int s1 = h(m, p);
  int q2 = cq_theta(q, 0.7);
  int s2 = h(m + 1, p);
  return cq_measure(s1) + cq_measure(s2) + cq_measure(q2);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
