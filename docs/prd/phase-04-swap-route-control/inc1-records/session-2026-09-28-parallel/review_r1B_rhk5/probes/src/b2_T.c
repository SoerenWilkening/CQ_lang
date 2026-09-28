#include <stdlib.h>
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  int q2 = cq_theta(q, 0.7);
  int s = p + 1;
  return cq_measure(s) + cq_measure(q2);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
