#include <stdlib.h>
__attribute__((noinline)) int slice(int m, int s) {
  int acc = 0;
  for (int k = 0; k < 3; k++) {
    int q = cq_theta(m + k, 0.5);
    int r = s;
    if (q > 3) r = cq_theta(s, 0.2);
    s = cq_measure(r) + 1;
    acc += s;
  }
  return acc;
}
int main(int c, char **v) { return slice(atoi(v[1]), atoi(v[2])); }
