#include <stdlib.h>
__attribute__((noinline)) int slice(int m, int n) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  for (int i = 0; i < 3; i++) { if ((p >> i) & 1) cq_phi(0.2); }
  int q2 = cq_theta(q, 0.7);
  return cq_measure(p) + cq_measure(q2);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])) & 1; }
