#include <stdlib.h>
__attribute__((noinline)) int g(int k) { return cq_theta(k, 0.7); }
__attribute__((noinline)) int h(int k) { return k*5; }
typedef int (*F)(int);
__attribute__((noinline)) static int slice(int m, int n, F f) {
  int q = cq_theta(0, 0.5);
  int r = f(m);
  int a = 7;
  if ((q > 1) & (r == n)) a += 3;
  return cq_measure(q) + cq_measure(a);
}
int main(int argc, char **argv) { return slice(atoi(argv[1]), atoi(argv[2]), argc > 5 ? h : g); }
