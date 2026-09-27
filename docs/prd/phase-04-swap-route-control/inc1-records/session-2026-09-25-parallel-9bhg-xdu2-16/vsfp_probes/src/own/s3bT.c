#include <stdlib.h>
int K(int x);
__attribute__((noinline)) int F(int m) { int q = cq_theta(m, .5); int r = 5; if (q > 3) r = K(m); int u = m + 1 + 0 * r; return u; }
int main(int c, char **v) { int m = atoi(v[1]); int x = F(m); return cq_measure(x) + x; }
