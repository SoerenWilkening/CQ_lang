#include <stdlib.h>
__attribute__((noinline)) int slice(int m, const int *s) {
  int acc = 0;
  { int q = cq_theta(m + 0, 0.5); int r = s[0]; if (q > 3) r = cq_theta(s[0], 0.2); acc += cq_measure(r); }
  { int q = cq_theta(m + 1, 0.5); int r = s[1]; if (q > 3) r = cq_theta(s[1], 0.2); acc += cq_measure(r); }
  { int q = cq_theta(m + 2, 0.5); int r = s[2]; if (q > 3) r = cq_theta(s[2], 0.2); acc += cq_measure(r); }
  return acc;
}
int main(int c, char **v) { int s[3] = {atoi(v[1]), atoi(v[2]), atoi(v[3])}; return slice(c + 3, s); }
