#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) {
  int b[4];
  for (int i = 0; i < 4; ++i) b[i] = cq_theta(b[i], 0.5);
  int t = h(b[0], m);
  return cq_measure(b[t & 3]);
}
int main(int c, char **v) { int m = atoi(v[1]); return f(m); }
