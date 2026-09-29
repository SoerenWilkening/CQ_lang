#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  int s = h(m, q);
  int t = h(m + 1, p);
  int v = h(m + 2, q);
  if (u == 10) cq_phi(3.14159);
  int ms = cq_measure(s) + cq_measure(t) + cq_measure(v);
  q = cq_theta(q, 0.7);
  return ms + cq_measure(q);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
