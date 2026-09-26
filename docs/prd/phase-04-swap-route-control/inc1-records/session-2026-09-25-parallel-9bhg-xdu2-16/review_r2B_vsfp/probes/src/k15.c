#include <stdlib.h>
int h(int a, int k);
int main(int c, char **v) { int m = atoi(v[1]); int q = cq_theta(m & 7, .5); int r = 0; for (int i = 0; i < 3; i++) { int p = q * 3; r += h(p, m); int u = p ^ q; r += cq_measure(u); } q = cq_theta(q, .7); return r + cq_measure(q); }
