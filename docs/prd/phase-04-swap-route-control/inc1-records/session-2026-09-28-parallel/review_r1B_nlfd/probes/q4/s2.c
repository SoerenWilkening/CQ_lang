#include <stdlib.h>
int h2(int a, int k);
__attribute__((noinline)) int f(int m, int k) {
  int y = cq_theta(5, 0.5); int s = 0;
  for (int i = 0; i < 2; ++i) { int u = cq_theta(6, 0.4); s += cq_measure((u >> 1) & 1) + cq_measure(y & 1); }
  s += cq_measure(y);
  __attribute__((musttail)) return h2(y, s + k);
}
int main(int c, char **v) { int m = atoi(v[1]); return f(m, m); }
