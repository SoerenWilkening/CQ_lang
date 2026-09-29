#include <stdlib.h>
#include <stdio.h>
int h(int a, int k); int ext_f(int a);
int main(int argc, char **v) {
  int c = atoi(v[1]); int n = atoi(v[2]);
  int q = cq_theta(c, 0.5); int y = 0;
  if (q > 5) y = ext_f(7);
  int t = y + c;
  if (c > 1000) puts("x");
  int q2 = cq_theta(n, 0.3);
  int r = t; if (q2 > 3) r = cq_theta(t, 0.2);
  return cq_measure(r) + cq_measure(q) + cq_measure(y) + cq_measure(q2);
}
