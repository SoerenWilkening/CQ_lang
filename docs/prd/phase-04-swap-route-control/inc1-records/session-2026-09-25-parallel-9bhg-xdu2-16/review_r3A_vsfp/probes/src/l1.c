#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int K = atoi(v[2]); int q = cq_theta(m & 7, .5); int r = 0;
  for (int i = 0; i < K; i++) { int p = q * 3; r += h(p, m + i); int u = p ^ q; if (u == 10) cq_phi(3.14159); }
  return r + cq_measure(q); }
