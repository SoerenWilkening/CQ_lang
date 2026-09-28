#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) {
  int m = atoi(v[1]); int t = atoi(v[2]);
  int q = cq_theta(m & 7, 0.5);
  int p = q * 3; int u = p ^ q;
  int s = q + 1;
  int r; if (u == 10) r = cq_theta(t, 0.7); else r = cq_theta(t, 0.2);
  int ms = cq_measure(s);
  q = cq_theta(q, 0.7);
  return ms + cq_measure(q) + cq_measure(r);
}
