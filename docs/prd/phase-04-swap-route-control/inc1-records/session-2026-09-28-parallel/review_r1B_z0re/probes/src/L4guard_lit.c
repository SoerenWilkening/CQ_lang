#include <stdlib.h>
__attribute__((noinline)) int slice(int m, int s0, int n) {
  const int s = 6; int r = s;
  for (int k = 0; k < n; k++) {
    int q = cq_theta(m + k, 0.5);
    r = s + k;
    if (q > k) r = cq_theta(s + k, 0.2);
  }
  return cq_measure(r);
}
int main(int c, char **v) { return slice(atoi(v[1]), atoi(v[2]), atoi(v[3])); }
