#include <stdlib.h>

__attribute__((noinline)) int f(int m, int k) {
  int q = cq_theta(m & 7, .5); int p = q * 3; int u = p ^ q;
  if (u == 10) cq_phi(3.14159);
  return k + 1;
}
int main(int c, char **v) { int m = atoi(v[1]); return f(m, m); }
