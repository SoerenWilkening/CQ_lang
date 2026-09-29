#include <stdlib.h>
/* r2A l2m — l2i with a classical BREAK before the body's kickback, so the body's
   discharge point need not dominate the loop exit (layer-(2) attempt), plus a DEAD
   sibling u of p in p's component. */
int h(int a, int k);
__attribute__((noinline)) int slice(int m, int b) {
  int q = cq_theta(m, 0.5);
  int r = cq_theta(m, 0.3);
  int p = q * 3;
  int t = 0;
  for (int i = 0; i < 3; i++) { if (i == b) break; if ((p >> i) & 1) cq_phi(0.2); r = cq_theta(r, 0.1); t += cq_measure(h(m + i, p)); }
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r) + t;
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])) & 1; }
