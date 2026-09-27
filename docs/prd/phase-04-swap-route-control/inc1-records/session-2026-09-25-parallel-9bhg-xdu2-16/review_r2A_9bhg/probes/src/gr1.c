#include <stdlib.h>
int K(int x); int h2(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m, .5); int r = 5; if (q > 3) r = K(m);
  int w = 1, x = 4; if (r > 7) { cq_phi(.3); w = 2; x = 9; }
  int u = h2(q, w); return cq_measure(u) + cq_measure(q) + x; }
