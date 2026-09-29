#include <stdlib.h>
__attribute__((noinline)) int w(int m, int k) {
  int q = cq_theta(m & 7, .5); int p = q * 3;
  if (p == 6) cq_phi(3.14159); return k + 1;
}
int main(int c, char **v) { int m = atoi(v[1]); return w(m, m) - m; }
