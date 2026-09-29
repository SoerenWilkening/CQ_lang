#include <stdlib.h>
__attribute__((noinline)) int g(int k) { return k * 7; }
__attribute__((noinline)) int f(int a, int b) { return g(a) + b; }
__attribute__((noinline)) int slice(int m) {
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3;
  int u = p ^ q;
  int s = f(q, p);
  if (u == 10) cq_phi(3.14159);
  int ms = cq_measure(s);
  q = cq_theta(q, 0.7);
  return ms + cq_measure(q);
}
int main(int argc, char **argv) { return slice(atoi(argv[1])) & 1; }
