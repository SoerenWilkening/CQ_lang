#include <stdlib.h>
int h(int a, int k);
__attribute__((noinline)) int f(int m) { int q = cq_theta(m, .5); int t = h(q, m); return t; }
int main(int c, char **v) { int m = atoi(v[1]); _Bool b = cq_theta((_Bool)(m & 1), .5); int p = b ? 9 : 4; int u = h(p, f(m)); b = cq_theta(b, .7); return u + cq_measure(b); }
