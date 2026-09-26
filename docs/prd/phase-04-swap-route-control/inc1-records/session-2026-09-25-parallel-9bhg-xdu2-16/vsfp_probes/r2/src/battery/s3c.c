#include <stdlib.h>
int K(int x); int h(int a, int k);
__attribute__((noinline)) int F(int m) { int q = cq_theta(m, .5); int r = 5; if (q > 3) r = K(m); int u = h(r, m); q = cq_theta(q, .7); return u + cq_measure(q); }
int main(int c, char **v) { int m = atoi(v[1]); return F(m); }
