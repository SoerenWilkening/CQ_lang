#include <stdlib.h>
int h(int a, int k); int K(int x);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int r = 5; if (q > 3) r = K(t); return r; }
int main(int c, char **v) { int m = atoi(v[1]); int x = f(m); return cq_measure(x) * 10 + x; }
