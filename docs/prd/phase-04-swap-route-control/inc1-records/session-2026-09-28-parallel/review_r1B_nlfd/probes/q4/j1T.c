#include <stdlib.h>
__attribute__((noinline)) int f(int m, int k) {
  _Bool b = cq_theta((_Bool)(m & 1), .5);
  b = cq_theta(b, .7); int t = cq_measure(b);
  return t + k + 1;
}
int main(int c, char **v) { int m = atoi(v[1]); return f(m, m); }
