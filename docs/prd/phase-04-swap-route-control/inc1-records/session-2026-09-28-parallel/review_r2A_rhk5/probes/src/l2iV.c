#include <stdlib.h>
/* hand-UNROLLED twin of l2i, clone call kept */
int h(int a, int k);
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m, 0.5);
  int r = cq_theta(m, 0.3);
  int p = q * 3;
  int t = 0;
  if ((p >> 0) & 1) cq_phi(0.2); r = cq_theta(r, 0.1); t += cq_measure(h(m + 0, p));
  if ((p >> 1) & 1) cq_phi(0.2); r = cq_theta(r, 0.1); t += cq_measure(h(m + 1, p));
  if ((p >> 2) & 1) cq_phi(0.2); r = cq_theta(r, 0.1); t += cq_measure(h(m + 2, p));
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r) + t;
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
