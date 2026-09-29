#include <stdlib.h>
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  int s = p + 1;
  int ms = cq_measure(s);
  q = cq_theta(q, 0.7);
  return ms + cq_measure(q);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
