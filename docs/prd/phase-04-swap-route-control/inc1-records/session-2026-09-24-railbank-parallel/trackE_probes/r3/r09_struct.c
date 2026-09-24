#include <stdlib.h>
struct P { int a, b, c, d, e; };
__attribute__((noinline)) struct P g(int k) { struct P p = {cq_theta(k, 0.7), k, k, k, k}; return p; }
__attribute__((noinline)) static int slice(int m, int n) {
  int q = cq_theta(0, 0.5);
  struct P p = g(m);
  int a = 7;
  if ((q > 1) & (p.a == n)) a += 3;
  return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
