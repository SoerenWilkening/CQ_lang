#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]); int n = atoi(v[2]);
  int q = cq_theta(m & 7, .5);
  int p = m, s = 7;
  if (q > 3) { p = 100 / n; s = 5; }
  int t = h(p, m);
  return t + cq_measure(s) + cq_measure(q);
}
