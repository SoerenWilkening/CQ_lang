#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int slice(int m, int n) {
  int q = cq_theta(m & 7, 0.5);
  int r = cq_theta(m, 0.3);
  int p = q * 3;
  int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  for (int i = 0; i < 3; i++) { if ((p >> i) & 1) cq_phi(0.2); r = cq_theta(r, 0.1); }
  int s = h(m, p);
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r) + cq_measure(s);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])) & 1; }
