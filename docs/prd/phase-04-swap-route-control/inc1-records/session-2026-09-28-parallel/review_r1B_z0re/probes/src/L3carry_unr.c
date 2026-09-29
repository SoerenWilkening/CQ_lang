#include <stdlib.h>
__attribute__((noinline)) int slice(int m, int s) {
  int r = s;
  { int q = cq_theta(m + 0, 0.5); r = s + 0; if (q > 0) r = cq_theta(s + 0, 0.2); }
  { int q = cq_theta(m + 1, 0.5); r = s + 1; if (q > 1) r = cq_theta(s + 1, 0.2); }
  { int q = cq_theta(m + 2, 0.5); r = s + 2; if (q > 2) r = cq_theta(s + 2, 0.2); }
  return cq_measure(r);
}
int main(int c, char **v) { return slice(atoi(v[1]), atoi(v[2])); }
