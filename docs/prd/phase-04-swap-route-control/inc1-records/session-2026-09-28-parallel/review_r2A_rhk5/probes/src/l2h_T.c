#include <stdlib.h>
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m, 0.5);
  int r = cq_theta(m, 0.3);
  int p = q * 3;
  for (int i = 0; i < 3; i++) { if ((p >> i) & 1) cq_phi(0.2); r = cq_theta(r, 0.1); }
  int s = p + 1;
  q = cq_theta(q, 0.9);
  return cq_measure(q) + cq_measure(r) + cq_measure(s);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
