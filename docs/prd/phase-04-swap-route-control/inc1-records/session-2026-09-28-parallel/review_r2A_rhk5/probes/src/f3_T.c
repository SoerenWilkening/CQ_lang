#include <stdlib.h>
/* r2A f3 — f2 with BOTH clones before the Ry: whole plan {p,w,u} should win */
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q & 3;
  int w = q * 5;
  int u = p ^ w;
  if (u == 10) cq_phi(3.14159);
  int s1 = (p + 1);
  int s2 = (w + 1);
  int q2 = cq_theta(q, 0.7);
  return cq_measure(s1) + cq_measure(s2) + cq_measure(q2);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
