#include <stdlib.h>
int h(int a, int k);

__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); int r = t; if (m > 3) r = cq_theta(t, .2); return r; }
int main(int c, char **v) { int m = atoi(v[1]); return f(m) * 2; }
