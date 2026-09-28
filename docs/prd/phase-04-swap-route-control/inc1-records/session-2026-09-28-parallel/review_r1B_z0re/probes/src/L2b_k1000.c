#include <stdlib.h>
__attribute__((noinline)) int slice(int m, const int *s) {
  int acc = 0;
  for (int k = 0; k < 1000; k++) {
    int q = cq_theta(m + k, 0.5);
    int r = s[k];
    if (q > 3) r = cq_theta(s[k], 0.2);
    acc += cq_measure(r);
  }
  return acc;
}
int main(int c, char **v) { int s[3] = {atoi(v[1]), atoi(v[2]), atoi(v[3])}; return slice(c + 3, s); }
