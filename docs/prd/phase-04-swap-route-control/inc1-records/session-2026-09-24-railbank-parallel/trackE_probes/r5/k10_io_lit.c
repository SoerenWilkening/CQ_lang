#include <stdio.h>
#include <stdlib.h>
__attribute__((noinline)) int g(int m) { int q = cq_theta(m, .5); int v = 3; if (q > 5) { printf("%d", q); v = 7; } return v * m; }
__attribute__((noinline)) static int slice(int m, int n) {
  int q2 = cq_theta(0, .5); int a = 7;
  if ((q2 > 1) & (g(m) == n)) a += 3;
  return cq_measure(a) + cq_measure(q2);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2])); }
