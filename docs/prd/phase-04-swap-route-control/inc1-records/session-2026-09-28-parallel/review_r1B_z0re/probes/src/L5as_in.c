#include <stdlib.h>
__attribute__((noinline)) int slice(int m, int t) {
  int acc = 0;
  for (int k = 0; k < 3; k++) {
    int q = cq_theta(m + k, 0.5);
    int r;
    if (q > k) r = cq_theta(t + k, 0.7); else r = cq_theta(t + k, 0.2);
    acc += cq_measure(r);
  }
  return acc;
}
int main(int c, char **v) { return slice(atoi(v[1]), atoi(v[2])); }
