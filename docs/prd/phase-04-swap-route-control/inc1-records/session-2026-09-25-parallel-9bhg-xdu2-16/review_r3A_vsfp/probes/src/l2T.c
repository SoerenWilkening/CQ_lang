#include <stdlib.h>
int main(int c, char **v) { int m = atoi(v[1]); int K = atoi(v[2]); int q = cq_theta(m & 7, .5); int r = 0;
  for (int i = 0; i < K; i++) { int p = q * i; r += m + i + 1; if (p == 6) cq_phi(3.14159); }
  return r + cq_measure(q); }
