#include <stdlib.h>
__attribute__((noinline)) int f(int m, int k) {
  int y = cq_theta(m & 7, .5); int s = 0;
  for (int i = 0; i < k; ++i) { int u = cq_theta(6, .4); s += cq_measure((u >> 1) & 1) + cq_measure(y & 1); }
  s += cq_measure(y);
  return s + 1;
}
int main(int c, char **v) { int m = atoi(v[1]); return f(m, 2); }
