#include <stdlib.h>
__attribute__((noinline)) int g(int k) { return cq_theta(k, 0.7); }
__attribute__((noinline)) static int slice(int m, int n) {
  int q = cq_theta(0, 0.5);
  int r = g(m);
  int mx = r > n ? r : n;
  int a = 7;
  if ((q > 1) & (mx == 5)) a += 3;
  return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
