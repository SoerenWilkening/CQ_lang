#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int slice(int m, int n) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  for (int i = 0; i < 3; i++) { if ((p >> i) & 1) cq_phi(0.2); }
  int s = h(m, p);
  int q2 = cq_theta(q, 0.7);
  return cq_measure(s) + cq_measure(q2);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])) & 1; }
