#include <stdlib.h>
int G;
__attribute__((noinline)) void g(int k) { G = cq_theta(k, 0.7); }
__attribute__((noinline)) static int slice(int m, int n) {
  int q = cq_theta(0, 0.5);
  g(m);
  int a = 7;
  if ((q > 1) & (G == n)) a += 3;
  return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
