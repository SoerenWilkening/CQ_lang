#include <stdlib.h>
__attribute__((noinline)) int slice(int m, int s) {
  int acc = 0;
  { int q = cq_theta(m + 0, 0.5); int r = s; if (q > 3) r = cq_theta(s, 0.2); s = cq_measure(r) + 1; acc += s; }
  { int q = cq_theta(m + 1, 0.5); int r = s; if (q > 3) r = cq_theta(s, 0.2); s = cq_measure(r) + 1; acc += s; }
  { int q = cq_theta(m + 2, 0.5); int r = s; if (q > 3) r = cq_theta(s, 0.2); s = cq_measure(r) + 1; acc += s; }
  return acc;
}
int main(int c, char **v) { return slice(atoi(v[1]), atoi(v[2])); }
